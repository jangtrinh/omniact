import SwiftUI

struct HUDQuickActionsView: View {
    let actions: [HUDQuickAction]
    let runAction: (HUDQuickAction) -> Void
    @State private var hoveredActionID: String?

    var body: some View {
        if !actions.isEmpty {
            HStack(spacing: 6) {
                ForEach(actions) { action in
                    NativeActionPill(
                        title: action.title,
                        icon: action.icon,
                        command: action.command,
                        isHovered: hoveredActionID == action.id
                    ) {
                        runAction(action)
                    }
                    .onHover { isHovered in
                        hoveredActionID = isHovered ? action.id : nil
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Quick command actions")
        }
    }
}

struct NativeActionPill: View {
    let title: String
    let icon: String
    let command: String
    let isHovered: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 11.5, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(isHovered ? 0.16 : 0.08))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(isHovered ? 0.28 : 0.12), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) quick action")
        .accessibilityValue(command)
        .accessibilityHint("Runs the current enabled command")
    }
}
