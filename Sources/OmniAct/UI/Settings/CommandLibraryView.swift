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
        Form {
            Section {
                HStack {
                    Button("Add Command", systemImage: "plus") { model.beginCreate() }
                        .buttonStyle(.borderedProminent)
                    Button("Reset Factory Commands") { isResettingAll = true }
                    Spacer()
                }
            } header: {
                Text("Command library")
            } footer: {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Edit the actions available from the OmniAct HUD. Use {text} for input and {arg} for text after the command.")
                    Text("Stored locally: \(store.directory.path)")
                        .font(.caption.monospaced())
                }
            }

            warnings

            if let draft = model.draft {
                Section(model.editingID == nil ? "New command" : "Edit command") {
                    CommandEditorView(model: model, draft: draft)
                }
            } else {
                Section("Commands") {
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

            if let error = model.actionError {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
        }
        .formStyle(.grouped)
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
            Button("Reset All Factory Commands", role: .destructive) {
                model.resetAllFactoryCommands()
            }
        } message: {
            Text("All factory overrides will be removed. Custom commands stay saved.")
        }
    }

    @ViewBuilder
    private var warnings: some View {
        if !store.loadWarnings.isEmpty {
            Section {
                ForEach(store.loadWarnings, id: \.self) { warning in
                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
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
