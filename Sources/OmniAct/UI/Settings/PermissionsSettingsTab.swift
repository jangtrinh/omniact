import AppKit
import SwiftUI

struct PermissionsSettingsTab: View {
    @State private var isAccessibilityGranted = false
    @State private var signingIdentity = AppSigningIdentityStatus.current()

    var body: some View {
        Form {
            Section {
                LabeledContent {
                    HStack(spacing: 10) {
                        Label(readiness.statusLabel, systemImage: statusIcon)
                            .foregroundStyle(statusColor)
                        if !isAccessibilityGranted {
                            Button(readiness.actionTitle) {
                                AccessibilityService.shared.requestAccessibilityPermission()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                } label: {
                    SettingsRowLabel("macOS Accessibility", detail: accessibilityDetail)
                }

                LabeledContent {
                    Text("⌥ Space")
                        .monospaced()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
                        .accessibilityLabel("Option Space")
                } label: {
                    SettingsRowLabel(
                        "Global shortcut",
                        detail: "Available from any app while OmniAct is running"
                    )
                }
            } header: {
                Text("System access")
            } footer: {
                Text("OmniAct checks permission status locally on this Mac.")
            }

            Section {
                SettingsCallout(
                    icon: "hand.raised.fill",
                    title: readiness.hasStableSigningIdentity
                        ? "Why OmniAct asks"
                        : "Build identity requires attention",
                    message: readiness.hasStableSigningIdentity
                        ? "Accessibility lets OmniAct read selected text and insert results in the active app."
                        : readiness.detail
                )
            }
        }
        .formStyle(.grouped)
        .onAppear(perform: refreshAccessibility)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshAccessibility()
        }
    }

    private var accessibilityDetail: String {
        readiness.detail
    }

    private var readiness: AccessibilityPermissionReadiness {
        AccessibilityPermissionReadiness(
            isAccessibilityGranted: isAccessibilityGranted,
            signingIdentity: signingIdentity
        )
    }

    private var statusIcon: String {
        switch readiness.state {
        case .granted:
            "checkmark.circle.fill"
        case .grantedForCurrentBuild, .notGranted, .unstableBuildIdentity:
            "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: Color {
        readiness.state == .granted ? .green : .orange
    }

    private func refreshAccessibility() {
        isAccessibilityGranted = AccessibilityService.shared.isAccessibilityGranted
        signingIdentity = AppSigningIdentityStatus.current()
    }
}
