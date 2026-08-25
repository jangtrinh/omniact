import Foundation

struct HUDQuickAction: Identifiable, Equatable, Sendable {
    let commandID: String
    let command: String
    let argument: String
    let title: String
    let icon: String

    var id: String { commandID }

    func input(using command: SlashCommand) -> String {
        argument.isEmpty ? command.command : "\(command.command) \(argument)"
    }
}

enum HUDQuickActionCatalog {
    private static let presets: [(commandID: String, argument: String)] = [
        ("factory.fix", ""),
        ("factory.tone", "formal"),
        ("factory.translate", "vi"),
        ("factory.summarize", "")
    ]

    static func visibleActions(from commands: [SlashCommand]) -> [HUDQuickAction] {
        presets.compactMap { preset in
            guard let command = commands.first(where: { $0.id == preset.commandID && $0.enabled }) else {
                return nil
            }
            return HUDQuickAction(
                commandID: command.id,
                command: command.command,
                argument: preset.argument,
                title: command.title,
                icon: command.icon
            )
        }
    }
}

enum HUDAutocompleteNavigationDirection: Sendable {
    case up
    case down
}

enum HUDAutocompleteViewport {
    static let visibleRowBudget = 6

    static func visibleRowCount(for commandCount: Int) -> Int {
        min(max(commandCount, 0), visibleRowBudget)
    }

    static func selectedStableID(commands: [SlashCommand], selectedIndex: Int?) -> String? {
        guard let selectedIndex, commands.indices.contains(selectedIndex) else { return nil }
        return commands[selectedIndex].id
    }
}

enum HUDAutocompleteSelection {
    static func movedIndex(
        from currentIndex: Int?,
        commandCount: Int,
        direction: HUDAutocompleteNavigationDirection
    ) -> Int? {
        guard commandCount > 0 else { return nil }
        let current = min(max(currentIndex ?? 0, 0), commandCount - 1)
        switch direction {
        case .up:
            return current == 0 ? commandCount - 1 : current - 1
        case .down:
            return current == commandCount - 1 ? 0 : current + 1
        }
    }
}

extension HUDViewModel {
    var quickActions: [HUDQuickAction] {
        HUDQuickActionCatalog.visibleActions(from: commandRouter.commands)
    }

    public func selectCommand(_ command: SlashCommand) {
        guard prepareCommandSelection(command) else { return }
        execute()
    }

    public func runQuickCommand(_ input: String) {
        guard let command = commandRouter.resolveCommand(from: input).0,
              prepareCommandSelection(command, input: input) else {
            return
        }
        execute()
    }

    func runQuickAction(_ action: HUDQuickAction) {
        guard prepareQuickAction(action) else { return }
        execute()
    }

    func quickActionInput(for action: HUDQuickAction) -> String? {
        guard let command = liveCommand(withID: action.commandID) else { return nil }
        return action.input(using: command)
    }

    @discardableResult
    func prepareQuickAction(_ action: HUDQuickAction) -> Bool {
        guard let command = liveCommand(withID: action.commandID),
              let input = quickActionInput(for: action) else {
            return false
        }
        return prepareCommandSelection(command, input: input)
    }

    func moveAutocompleteSelection(_ direction: HUDAutocompleteNavigationDirection) {
        guard inputText.hasPrefix("/") else { return }
        autocompleteSelectionIndex = HUDAutocompleteSelection.movedIndex(
            from: autocompleteSelectionIndex,
            commandCount: matchedCommands.count,
            direction: direction
        )
    }

    @discardableResult
    func prepareAutocompleteSelection(at index: Int? = nil) -> Bool {
        guard let selectedIndex = index ?? autocompleteSelectionIndex,
              matchedCommands.indices.contains(selectedIndex) else {
            return false
        }
        return prepareCommandSelection(matchedCommands[selectedIndex])
    }

    func submitCurrentInput() {
        if !streamedOutput.isEmpty && !isStreaming {
            acceptAndReplace()
        } else if inputText.hasPrefix("/"),
                  let selectedIndex = autocompleteSelectionIndex,
                  matchedCommands.indices.contains(selectedIndex) {
            selectCommand(matchedCommands[selectedIndex])
        } else {
            execute()
        }
    }

    func commandCatalogDidChange() {
        if let selected = selectedCommand {
            selectedCommand = liveCommand(withID: selected.id)
        }
        updateCommandMatching()
        onContentSizeChange?()
    }

    private func liveCommand(withID id: String) -> SlashCommand? {
        commandRouter.commands.first { $0.id == id }
    }

    @discardableResult
    private func prepareCommandSelection(_ command: SlashCommand, input: String? = nil) -> Bool {
        guard let selected = liveCommand(withID: command.id) else { return false }
        selectedCommand = selected
        inputText = input ?? "\(selected.command) "
        return true
    }
}
