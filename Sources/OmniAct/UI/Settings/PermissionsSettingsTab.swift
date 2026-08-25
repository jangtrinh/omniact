import AppKit
import SwiftUI

struct PermissionsSettingsTab: View {
    @State private var isAccessibilityGranted = false
    @State private var signingIdentity = AppSigningIdentityStatus.current()

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
                        Label(readiness.statusLabel, systemImage: statusIcon)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(statusColor)
                        if !isAccessibilityGranted {
                            Button(readiness.actionTitle) {
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
                title: readiness.hasStableSigningIdentity ? "Why OmniAct asks" : "Build identity requires attention",
                message: readiness.hasStableSigningIdentity
                    ? "Accessibility allows OmniAct to request text and simulated input. Compatibility depends on the active app."
                    : readiness.detail
            )
        }
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
