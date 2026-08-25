import Cocoa
import SwiftUI

@MainActor
public final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var hudPanel: HUDPanel?
    private var viewModel = HUDViewModel()
    private var previousApp: NSRunningApplication?
    private var settingsWindow: NSWindow?

    override public init() {
        super.init()
        setupStatusItem()
        setupHUD()
        setupHotKey()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "sparkle.magnifyingglass", accessibilityDescription: "OmniAct")
            button.imagePosition = .imageOnly
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Trigger OmniAct (⌥ Space)", action: #selector(toggleHUD), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences / Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Check Permissions", action: #selector(checkPermissions), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit OmniAct", action: #selector(quitApp), keyEquivalent: "q"))

        for item in menu.items {
            item.target = self
        }

        statusItem?.menu = menu
    }

    private func setupHUD() {
        let panel = HUDPanel(contentRect: NSRect(x: 0, y: 0, width: 540, height: 300))
        let hostingView = NSHostingView(rootView: FloatingHUDView(viewModel: viewModel))
        panel.contentView = hostingView

        viewModel.onDismiss = { [weak self] in
            self?.hideHUD()
        }

        viewModel.onAcceptAndReplace = { [weak self] text in
            self?.hideHUD(andReplace: text)
        }

        viewModel.onContentSizeChange = { [weak self] in
            Task { @MainActor in
                self?.hudPanel?.updateFrameToFitContent()
            }
        }

        self.hudPanel = panel
    }

    private func setupHotKey() {
        HotKeyManager.shared.register { [weak self] in
            Task { @MainActor in
                self?.toggleHUD()
            }
        }
    }

    @objc public func toggleHUD() {
        guard let panel = hudPanel else { return }

        if panel.isVisible {
            viewModel.cancel()
        } else {
            showHUD()
        }
    }

    public func showHUD() {
        guard let panel = hudPanel else { return }

        // Capture frontmost app BEFORE OmniAct gains focus
        let currentFrontApp = NSWorkspace.shared.frontmostApplication
        if currentFrontApp?.bundleIdentifier != Bundle.main.bundleIdentifier {
            self.previousApp = currentFrontApp
        }

        let context = AccessibilityService.shared.getContext(for: self.previousApp)
        viewModel.setContext(context)

        panel.positionNear(caretRect: context.caretRect)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func hideHUD(andReplace text: String? = nil) {
        hudPanel?.orderOut(nil)
        if text == nil {
            viewModel.resetForDismissal()
        }

        // Reactivate target app
        if let target = previousApp {
            target.activate()
        }

        if let textToInsert = text {
            // Give window server 100ms to refocus target app, then trigger paste
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                TextReplacer.shared.replaceSelectedText(with: textToInsert)
            }
        }
    }

    @objc private func checkPermissions() {
        if AccessibilityService.shared.isAccessibilityGranted {
            let alert = NSAlert()
            alert.messageText = "Accessibility Granted"
            alert.informativeText = "OmniAct has full accessibility access to read selected text and insert AI responses."
            alert.alertStyle = .informational
            alert.runModal()
        } else {
            AccessibilityService.shared.requestAccessibilityPermission()
        }
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 590, height: 500),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = "OmniAct Preferences"
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            window.isReleasedWhenClosed = false
            window.center()
            window.contentView = NSHostingView(rootView: SettingsView())
            self.settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
