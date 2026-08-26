import AppKit
import SwiftUI

@main
struct OmniActApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsWindowRoot()
        }
        .defaultSize(
            width: SettingsDesignMetrics.windowWidth,
            height: SettingsDesignMetrics.windowHeight
        )
        .windowResizability(.contentMinSize)
        .windowToolbarStyle(.unifiedCompact(showsTitle: true))
    }
}

private struct SettingsWindowRoot: View {
    @ViewBuilder
    var body: some View {
        if #available(macOS 15.0, *) {
            SettingsView()
                .windowMinimizeBehavior(.enabled)
                .windowResizeBehavior(.enabled)
                .windowFullScreenBehavior(.enabled)
        } else {
            SettingsView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure background agent mode
        NSApp.setActivationPolicy(.accessory)

        // Initialize status bar controller
        self.statusBarController = StatusBarController()

        print("OmniAct initialized. Press Option+Space to activate.")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotKeyManager.shared.unregister()
    }
}
