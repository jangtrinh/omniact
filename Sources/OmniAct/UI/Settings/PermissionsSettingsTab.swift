import SwiftUI

struct PermissionsSettingsTab: View {
    @State private var isAccessibilityGranted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System Permissions").font(.system(size: 14, weight: .semibold))
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: isAccessibilityGranted ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(isAccessibilityGranted ? .green : .orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("macOS Accessibility").font(.system(size: 13, weight: .medium))
                        Text(isAccessibilityGranted ? "Access granted. OmniAct can read selected text and replace inline." : "Permission required to read selected text across all apps.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if !isAccessibilityGranted {
                        Button("Grant Access") {
                            AccessibilityService.shared.requestAccessibilityPermission()
                            refreshAccessibility()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                Divider().opacity(0.2)
                HStack(spacing: 12) {
                    Image(systemName: "keyboard.fill").font(.system(size: 18)).foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Global Shortcut").font(.system(size: 13, weight: .medium))
                        Text("Press Option + Space (⌥ Space) from any app to activate.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.04))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5))
        }
        .onAppear(perform: refreshAccessibility)
    }

    private func refreshAccessibility() {
        isAccessibilityGranted = AccessibilityService.shared.isAccessibilityGranted
    }
}
