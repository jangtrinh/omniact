import Cocoa
import SwiftUI

@MainActor
public final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var hudPanel: HUDPanel?
    private var viewModel: HUDViewModel?
    private var previousApp: NSRunningApplication?

    override public init() {
        super.init()
        setupStatusItem()
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
        guard hudPanel == nil else { return }
        let viewModel = HUDViewModel()
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

        self.viewModel = viewModel
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
        setupHUD()
        guard let panel = hudPanel, let viewModel else { return }

        if panel.isVisible {
            viewModel.cancel()
        } else {
            showHUD()
        }
    }

    public func showHUD() {
        setupHUD()
        guard let panel = hudPanel, let viewModel else { return }

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
            viewModel?.resetForDismissal()
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
        NSApp.activate(ignoringOtherApps: true)
        guard let settingsItem = NSApp.mainMenu?
            .items
            .compactMap(\.submenu)
            .flatMap(\.items)
            .first(where: { $0.keyEquivalent == "," }),
              let action = settingsItem.action else {
            NSSound.beep()
            return
        }
        if !NSApp.sendAction(action, to: settingsItem.target, from: settingsItem) {
            NSSound.beep()
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
