import SwiftUI

struct CommandListRow: View {
    let command: SlashCommand
    let index: Int
    let count: Int
    let state: String
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onToggle: @MainActor @Sendable (Bool) -> Void
    let onMove: (Int) -> Void
    let onDelete: () -> Void
    let onReset: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: command.icon)
                .foregroundStyle(command.enabled ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(command.command)
                        .font(.body.monospaced().weight(.semibold))
                    Text(command.title)
                }
                Text(metadata)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 10)

            Toggle("Enable \(command.title)", isOn: Binding(get: { command.enabled }, set: onToggle))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .accessibilityLabel("\(command.title) enabled")
                .accessibilityValue(command.enabled ? "Enabled" : "Disabled")
                .accessibilityHint("Shows or hides this command in OmniAct")

            actionMenu
        }
        .padding(.vertical, 4)
        .opacity(command.enabled ? 1 : 0.6)
    }

    private var actionMenu: some View {
        Menu {
            Button("Edit", systemImage: "pencil", action: onEdit)
            Button("Duplicate", systemImage: "plus.square.on.square", action: onDuplicate)
            Divider()
            Button("Move Up", systemImage: "arrow.up", action: { onMove(-1) })
                .disabled(index == 0)
            Button("Move Down", systemImage: "arrow.down", action: { onMove(1) })
                .disabled(index == count - 1)
            Divider()
            if command.origin == .factory {
                Button("Reset", systemImage: "arrow.counterclockwise", action: onReset)
            } else {
                Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .imageScale(.large)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .accessibilityLabel("Actions for \(command.title)")
        .accessibilityValue("Position \(index + 1) of \(count)")
    }

    private var metadata: String {
        let aliases = command.aliases.isEmpty ? "" : " · \(command.displayAliases)"
        return "\(command.description) · \(state)\(aliases)"
    }
}
