import Cocoa
import ApplicationServices

public final class AccessibilityService: @unchecked Sendable {
    public static let shared = AccessibilityService()
    private static let trustedCheckOptionPrompt = "AXTrustedCheckOptionPrompt"

    private init() {}

    public var isAccessibilityGranted: Bool {
        let options = [Self.trustedCheckOptionPrompt: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    public func requestAccessibilityPermission() {
        let options = [Self.trustedCheckOptionPrompt: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    public func getContext(for app: NSRunningApplication? = nil) -> AXContext {
        let appToQuery = app ?? NSWorkspace.shared.frontmostApplication
        var selectedText = ""
        var caretRect: CGRect? = nil

        // MARK: - 1. Deep Accessibility Traversal on Target App
        if let targetApp = appToQuery, targetApp.bundleIdentifier != Bundle.main.bundleIdentifier {
            let appElement = AXUIElementCreateApplication(targetApp.processIdentifier)

            // Try focused UI element
            if let element = getFocusedElement(from: appElement) {
                let (text, rect) = extractTextAndBounds(from: element)
                if !text.isEmpty { selectedText = text }
                if rect != nil { caretRect = rect }
            }

            // If empty, try focused window -> focused element
            if selectedText.isEmpty {
                var focusedWindow: AnyObject?
                if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow) == .success,
                   let windowElement = focusedWindow as! AXUIElement? {
                    if let element = getFocusedElement(from: windowElement) {
                        let (text, rect) = extractTextAndBounds(from: element)
                        if !text.isEmpty { selectedText = text }
                        if caretRect == nil && rect != nil { caretRect = rect }
                    }
                }
            }
        }

        // MARK: - 2. System-Wide Accessibility Fallback
        if selectedText.isEmpty {
            let systemWide = AXUIElementCreateSystemWide()
            if let element = getFocusedElement(from: systemWide) {
                let (text, rect) = extractTextAndBounds(from: element)
                if !text.isEmpty { selectedText = text }
                if caretRect == nil && rect != nil { caretRect = rect }
            }
        }

        // MARK: - 3. RunLoop-Driven Simulated Copy (Cmd+C) Fallback
        if selectedText.isEmpty {
            selectedText = copySelectedTextFallback(for: appToQuery)
        }

        if caretRect == nil || caretRect == .zero {
            caretRect = fallbackCaretRect()
        }

        return AXContext(
            selectedText: selectedText,
            caretRect: caretRect,
            appName: appToQuery?.localizedName,
            bundleIdentifier: appToQuery?.bundleIdentifier
        )
    }

    private func getFocusedElement(from parent: AXUIElement) -> AXUIElement? {
        var focusedElement: AnyObject?
        if AXUIElementCopyAttributeValue(parent, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success,
           let element = focusedElement as! AXUIElement? {
            return element
        }
        return nil
    }

    private func extractTextAndBounds(from element: AXUIElement) -> (text: String, bounds: CGRect?) {
        var selectedText = ""
        var caretRect: CGRect? = nil

        // 1. Direct kAXSelectedTextAttribute
        var selectedTextValue: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedTextValue) == .success,
           let text = selectedTextValue as? String, !text.isEmpty {
            selectedText = text
        }

        // 2. Substring extraction via kAXSelectedTextRangeAttribute & kAXValueAttribute
        if selectedText.isEmpty {
            var selectedRangeValue: AnyObject?
            if AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &selectedRangeValue) == .success,
               let rangeVal = selectedRangeValue as! AXValue? {
                var range = CFRange()
                if AXValueGetValue(rangeVal, .cfRange, &range) && range.length > 0 {
                    var stringValue: AnyObject?
                    if AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &stringValue) == .success,
                       let fullString = stringValue as? String {
                        if range.location >= 0 && range.location + range.length <= fullString.count {
                            let start = fullString.index(fullString.startIndex, offsetBy: range.location)
                            let end = fullString.index(start, offsetBy: range.length)
                            selectedText = String(fullString[start..<end])
                        }
                    }
                }
            }
        }

        // 3. Extract Caret / Selection Bounds
        var selectedRangeValue: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &selectedRangeValue) == .success,
           let rangeVal = selectedRangeValue as! AXValue? {
            var boundsValue: AnyObject?
            if AXUIElementCopyParameterizedAttributeValue(element, kAXBoundsForRangeParameterizedAttribute as CFString, rangeVal, &boundsValue) == .success,
               let boundsVal = boundsValue as! AXValue? {
                var rect = CGRect.zero
                if AXValueGetValue(boundsVal, .cgRect, &rect) {
                    caretRect = rect
                }
            }
        }

        return (selectedText, caretRect)
    }

    private func copySelectedTextFallback(for app: NSRunningApplication?) -> String {
        let pasteboard = NSPasteboard.general
        let initialCount = pasteboard.changeCount
        let oldString = pasteboard.string(forType: .string)

        let src = CGEventSource(stateID: .hidSystemState)
        let cKeyCode: CGKeyCode = 0x08 // 'c'

        guard let keyDown = CGEvent(keyboardEventSource: src, virtualKey: cKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: src, virtualKey: cKeyCode, keyDown: false) else {
            return ""
        }

        keyDown.flags = .maskCommand
        keyUp.flags = []

        if let pid = app?.processIdentifier {
            keyDown.postToPid(pid)
            keyUp.postToPid(pid)
        } else {
            keyDown.post(tap: .cgSessionEventTap)
            keyUp.post(tap: .cgSessionEventTap)
        }

        // RunLoop pump to receive IPC pasteboard notifications from target app
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < 0.08 {
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.008))
            if pasteboard.changeCount != initialCount {
                if let captured = pasteboard.string(forType: .string), !captured.isEmpty {
                    // Restore previous clipboard quietly
                    if let old = oldString {
                        pasteboard.clearContents()
                        pasteboard.setString(old, forType: .string)
                    }
                    return captured
                }
            }
        }

        return ""
    }

    private func fallbackCaretRect() -> CGRect {
        let mouseLocation = NSEvent.mouseLocation
        return CGRect(x: mouseLocation.x, y: mouseLocation.y, width: 1, height: 20)
    }
}
