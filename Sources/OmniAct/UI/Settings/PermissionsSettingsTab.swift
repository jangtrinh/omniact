import AppKit
import SwiftUI

struct PermissionsSettingsTab: View {
    @State private var isAccessibilityGranted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("System access")
                    .font(.headline)
                Text("OmniAct checks permissions locally on this Mac.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            SettingsCard {
                SettingsRow(
                    title: "macOS Accessibility",
                    detail: accessibilityDetail
                ) {
                    HStack(spacing: 10) {
                        Label(
                            isAccessibilityGranted ? "Granted" : "Required",
                            systemImage: isAccessibilityGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                        )
                        .font(.callout.weight(.medium))
                        .foregroundStyle(isAccessibilityGranted ? Color.green : Color.orange)
                        if !isAccessibilityGranted {
                            Button("Grant Access") {
                                AccessibilityService.shared.requestAccessibilityPermission()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                Divider().padding(.leading, 16)
                SettingsRow(
                    title: "Global shortcut",
                    detail: "Available from any app while OmniAct is running"
                ) {
                    Text("⌥ Space")
                        .font(.body.monospaced())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                        .accessibilityLabel("Option Space")
                }
            }
            SettingsCallout(
                icon: "hand.raised.fill",
                title: "Why OmniAct asks",
                message: "Accessibility lets OmniAct read selected text and insert a response in the active app."
            )
        }
        .onAppear(perform: refreshAccessibility)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshAccessibility()
        }
    }

    private var accessibilityDetail: String {
        isAccessibilityGranted
            ? "OmniAct can read selected text and replace it inline."
            : "Required to read selected text and insert responses."
    }

    private func refreshAccessibility() {
        isAccessibilityGranted = AccessibilityService.shared.isAccessibilityGranted
    }
}
