import AppKit
import SwiftUI

struct SettingsWindowConfigurator: NSViewRepresentable {
    let sectionTitle: String

    func makeNSView(context: Context) -> NSView {
        SettingsWindowHostView(sectionTitle: sectionTitle)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let hostView = nsView as? SettingsWindowHostView else { return }
        hostView.updateSectionTitle(sectionTitle)
    }
}

@MainActor
private final class SettingsWindowHostView: NSView {
    private var didConfigureWindow = false
    private var leadingHostingView: NSHostingView<AnyView>?
    private var sectionTitle: String

    init(sectionTitle: String) {
        self.sectionTitle = sectionTitle
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window, !didConfigureWindow else { return }
        didConfigureWindow = true

        window.title = "OmniAct Settings"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.titlebarSeparatorStyle = .none
        installTitlebarAccessories(in: window)
        window.makeFirstResponder(nil)
        DispatchQueue.main.async { [weak window] in
            NSApp.activate(ignoringOtherApps: true)
            window?.makeKeyAndOrderFront(nil)
            window?.makeFirstResponder(window?.contentView)
        }
    }

    func updateSectionTitle(_ title: String) {
        sectionTitle = title
        leadingHostingView?.rootView = AnyView(SettingsTitlebarLeading(title: title))
    }

    private func installTitlebarAccessories(in window: NSWindow) {
        removeExistingTitlebarAccessories(from: window)

        let leadingView = NSHostingView(rootView: AnyView(SettingsTitlebarLeading(title: sectionTitle)))
        leadingView.identifier = .omniActSettingsTitlebarLeading
        leadingView.frame.size = NSSize(width: 340, height: SettingsDesignMetrics.toolbarHeight)
        let leadingController = NSTitlebarAccessoryViewController()
        leadingController.layoutAttribute = .left
        leadingController.view = leadingView

        let trailingView = NSHostingView(rootView: AnyView(SettingsTitlebarTrailing()))
        trailingView.identifier = .omniActSettingsTitlebarTrailing
        trailingView.frame.size = NSSize(width: 116, height: SettingsDesignMetrics.toolbarHeight)
        let trailingController = NSTitlebarAccessoryViewController()
        trailingController.layoutAttribute = .right
        trailingController.view = trailingView

        window.addTitlebarAccessoryViewController(leadingController)
        window.addTitlebarAccessoryViewController(trailingController)
        leadingHostingView = leadingView
    }

    private func removeExistingTitlebarAccessories(from window: NSWindow) {
        let ownedIdentifiers: Set<NSUserInterfaceItemIdentifier> = [
            .omniActSettingsTitlebarLeading,
            .omniActSettingsTitlebarTrailing
        ]
        for index in window.titlebarAccessoryViewControllers.indices.reversed() {
            let controller = window.titlebarAccessoryViewControllers[index]
            if let identifier = controller.view.identifier,
               ownedIdentifiers.contains(identifier) {
                window.removeTitlebarAccessoryViewController(at: index)
            }
        }
    }
}

private extension NSUserInterfaceItemIdentifier {
    static let omniActSettingsTitlebarLeading = Self("OmniAct.Settings.Titlebar.Leading")
    static let omniActSettingsTitlebarTrailing = Self("OmniAct.Settings.Titlebar.Trailing")
}
