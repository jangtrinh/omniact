import Combine
import Foundation

@MainActor
final class CommandLibraryViewModel: ObservableObject {
    let store: CommandStore
    @Published var draft: SlashCommand?
    @Published var editingID: String?
    @Published var validationIssues: [CommandValidationIssue] = []
    @Published var actionError: String?

    init(store: CommandStore) {
        self.store = store
    }

    func beginCreate() {
        draft = SlashCommand.newCustom(order: store.commands.count)
        editingID = nil
        clearValidationErrors()
    }

    func beginEdit(_ command: SlashCommand) {
        draft = command
        editingID = command.id
        clearValidationErrors()
    }

    func cancelEditing() {
        draft = nil
        editingID = nil
        clearValidationErrors()
    }

    func updateDraft(_ change: (inout SlashCommand) -> Void) {
        guard var draft else { return }
        change(&draft)
        self.draft = draft
        clearValidationErrors()
    }

    func setAliases(_ text: String) {
        updateDraft { draft in
            draft.aliases = text.split(separator: ",", omittingEmptySubsequences: false)
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        }
    }

    func saveDraft() {
        guard let draft else { return }
        let issues = store.validationIssues(for: draft, replacing: editingID)
        guard issues.isEmpty else {
            validationIssues = issues
            return
        }
        do {
            if editingID == nil {
                try store.create(draft)
            } else {
                try store.update(draft)
            }
            cancelEditing()
        } catch {
            record(error)
        }
    }

    func duplicate(_ command: SlashCommand) {
        do {
            let copy = try store.duplicate(id: command.id)
            beginEdit(copy)
        } catch {
            record(error)
        }
    }

    func setEnabled(_ enabled: Bool, for command: SlashCommand) {
        perform { try store.setEnabled(enabled, for: command.id) }
    }

    func move(_ command: SlashCommand, by offset: Int) {
        perform { try store.move(id: command.id, by: offset) }
    }

    func deleteCustom(_ command: SlashCommand) {
        perform { try store.deleteCustom(id: command.id) }
        if editingID == command.id { cancelEditing() }
    }

    func resetFactory(_ command: SlashCommand) {
        perform { try store.resetFactory(id: command.id) }
        if editingID == command.id { cancelEditing() }
    }

    func resetAllFactoryCommands() {
        perform { try store.resetAllFactoryCommands() }
        if draft?.origin == .factory { cancelEditing() }
    }

    func originState(for command: SlashCommand) -> String {
        if command.origin == .factory {
            return store.isFactoryModified(command) ? "Factory • modified" : "Factory • original"
        }
        return store.command(withID: command.id) == nil ? "Custom • unsaved" : "Custom • saved"
    }

    func clearValidationErrors() {
        validationIssues = []
        actionError = nil
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
            actionError = nil
        } catch {
            record(error)
        }
    }

    private func record(_ error: Error) {
        if let storeError = error as? CommandStoreError,
           case .validation(let issues) = storeError {
            validationIssues = issues
        } else {
            actionError = error.localizedDescription
        }
    }
}
