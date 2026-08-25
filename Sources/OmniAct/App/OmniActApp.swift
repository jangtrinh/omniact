import SwiftUI
import Cocoa

@main
struct OmniActApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(
            width: SettingsDesignMetrics.windowWidth,
            height: SettingsDesignMetrics.contentLayoutHeight
        )
        .windowResizability(.contentSize)
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
