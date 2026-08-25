import Cocoa
import CoreGraphics

public final class TextReplacer: @unchecked Sendable {
    public static let shared = TextReplacer()

    private init() {}

    public func replaceSelectedText(with replacement: String, completion: (@Sendable () -> Void)? = nil) {
        let pasteboard = NSPasteboard.general

        // 1. Backup old clipboard contents
        let oldString = pasteboard.string(forType: .string)

        // 2. Set replacement text to pasteboard
        pasteboard.clearContents()
        pasteboard.setString(replacement, forType: .string)

        // 3. Post Cmd+V event to simulate paste
        simulatePaste()

        // 4. Restore original clipboard after safe delay (0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if let oldString = oldString {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(oldString, forType: .string)
            }
            completion?()
        }
    }

    private func simulatePaste() {
        let src = CGEventSource(stateID: .combinedSessionState)

        let vKeyCode: CGKeyCode = 0x09 // 'v'

        guard let keyDown = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: false) else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
