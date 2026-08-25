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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: command.icon)
                    .foregroundColor(command.enabled ? .accentColor : .secondary)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(command.command).font(.system(size: 12, weight: .bold, design: .monospaced))
                        Text(command.title).font(.system(size: 12, weight: .medium))
                    }
                    Text(command.description).font(.system(size: 10.5)).foregroundColor(.secondary).lineLimit(1)
                }
                Spacer()
                Toggle("", isOn: Binding(get: { command.enabled }, set: onToggle))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.mini)
            }
            HStack(spacing: 7) {
                Text(state).font(.system(size: 10)).foregroundColor(.secondary)
                if !command.aliases.isEmpty {
                    Text("Aliases: \(command.displayAliases)").font(.system(size: 10)).foregroundColor(.secondary).lineLimit(1)
                }
                Spacer()
                Button("↑") { onMove(-1) }.disabled(index == 0)
                Button("↓") { onMove(1) }.disabled(index == count - 1)
                Button("Edit", action: onEdit)
                Button("Duplicate", action: onDuplicate)
                if command.origin == .factory {
                    Button("Reset", action: onReset)
                } else {
                    Button("Delete", role: .destructive, action: onDelete)
                }
            }
            .font(.system(size: 10.5))
        }
        .padding(10)
        .background(Color.white.opacity(command.enabled ? 0.04 : 0.015))
        .cornerRadius(8)
        .opacity(command.enabled ? 1 : 0.58)
    }
}
