import SwiftUI

struct CommandLibraryView: View {
    @ObservedObject private var store: CommandStore
    @StateObject private var model: CommandLibraryViewModel
    @State private var pendingDeletion: SlashCommand?
    @State private var pendingFactoryReset: SlashCommand?
    @State private var isResettingAll = false

    @MainActor
    init(store: CommandStore? = nil) {
        let resolvedStore = store ?? CommandStore.shared
        _store = ObservedObject(wrappedValue: resolvedStore)
        _model = StateObject(wrappedValue: CommandLibraryViewModel(store: resolvedStore))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            warnings
            if let draft = model.draft {
                CommandEditorView(model: model, draft: draft)
            } else {
                commandList
            }
            if let error = model.actionError {
                Text(error).font(.system(size: 11)).foregroundColor(.orange)
            }
        }
        .confirmationDialog("Delete this custom command?", isPresented: deletionPresented) {
            Button("Delete", role: .destructive) {
                if let command = pendingDeletion { model.deleteCustom(command) }
                pendingDeletion = nil
            }
        } message: {
            Text("This removes its local JSON file. Factory commands can be reset instead.")
        }
        .confirmationDialog("Reset this factory command?", isPresented: factoryResetPresented) {
            Button("Reset", role: .destructive) {
                if let command = pendingFactoryReset { model.resetFactory(command) }
                pendingFactoryReset = nil
            }
        } message: {
            Text("Its local override will be removed and the shipped definition restored.")
        }
        .confirmationDialog("Reset all factory commands?", isPresented: $isResettingAll) {
            Button("Reset All Factory Commands", role: .destructive) { model.resetAllFactoryCommands() }
        } message: {
            Text("All factory overrides will be removed. Custom commands stay saved.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Command library")
                        .font(.headline)
                    Text("Edit the actions available from the OmniAct HUD.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Add") { model.beginCreate() }.buttonStyle(.borderedProminent)
                Button("Reset All Factory") { isResettingAll = true }.buttonStyle(.bordered)
            }
            Text("Local only: \(store.directory.path)")
                .font(.caption.monospaced())
                .foregroundColor(.secondary)
            Text("Use {text} for selected or typed text and {arg} for text after the command token.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var warnings: some View {
        if !store.loadWarnings.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                ForEach(store.loadWarnings, id: \.self) { warning in
                    Text(warning).font(.caption).foregroundColor(.orange)
                }
            }
            .padding(8)
            .background(Color.orange.opacity(0.12))
            .cornerRadius(6)
        }
    }

    private var commandList: some View {
        VStack(spacing: 8) {
            ForEach(Array(store.commands.enumerated()), id: \.element.id) { index, command in
                CommandListRow(
                    command: command,
                    index: index,
                    count: store.commands.count,
                    state: model.originState(for: command),
                    onEdit: { model.beginEdit(command) },
                    onDuplicate: { model.duplicate(command) },
                    onToggle: { model.setEnabled($0, for: command) },
                    onMove: { model.move(command, by: $0) },
                    onDelete: { pendingDeletion = command },
                    onReset: { pendingFactoryReset = command }
                )
            }
        }
    }

    private var deletionPresented: Binding<Bool> {
        Binding(get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } })
    }

    private var factoryResetPresented: Binding<Bool> {
        Binding(get: { pendingFactoryReset != nil }, set: { if !$0 { pendingFactoryReset = nil } })
    }
}
