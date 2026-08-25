import Foundation

public extension CommandStore {
    @discardableResult
    func create(_ draft: SlashCommand) throws -> SlashCommand {
        guard command(withID: draft.id) == nil else { throw CommandStoreError.validation([.duplicateIdentifier]) }
        var command = copy(draft, id: draft.id.isEmpty ? UUID().uuidString.lowercased() : draft.id, origin: .custom)
        command.order = nextOrder()
        try saveCatalog(commands + [command], changedIDs: [command.id])
        return command
    }

    func update(_ draft: SlashCommand) throws {
        guard let existing = command(withID: draft.id) else { throw CommandStoreError.commandNotFound }
        let updated = copy(draft, id: existing.id, origin: existing.origin, order: existing.order)
        try saveCatalog(commands.map { $0.id == existing.id ? updated : $0 }, changedIDs: [existing.id])
    }

    @discardableResult
    func duplicate(id: String) throws -> SlashCommand {
        guard let source = command(withID: id) else { throw CommandStoreError.commandNotFound }
        let duplicate = SlashCommand(
            id: UUID().uuidString.lowercased(),
            command: availableDuplicateToken(for: source.command),
            title: "Copy of \(source.title)",
            description: source.description,
            icon: source.icon,
            systemPrompt: source.systemPrompt,
            promptTemplate: source.promptTemplate,
            enabled: source.enabled,
            origin: .custom,
            order: nextOrder()
        )
        return try create(duplicate)
    }

    func setEnabled(_ enabled: Bool, for id: String) throws {
        guard var command = command(withID: id) else { throw CommandStoreError.commandNotFound }
        command.enabled = enabled
        try update(command)
    }

    func move(id: String, by offset: Int) throws {
        var reordered = Self.sorted(commands)
        guard let index = reordered.firstIndex(where: { $0.id == id }) else { throw CommandStoreError.commandNotFound }
        let destination = max(0, min(reordered.count - 1, index + offset))
        guard destination != index else { return }
        let command = reordered.remove(at: index)
        reordered.insert(command, at: destination)
        for index in reordered.indices {
            reordered[index].order = index
        }
        let changedIDs = Set(reordered.compactMap { command -> String? in
            guard let existing = commands.first(where: { $0.id == command.id }), existing != command else {
                return nil
            }
            return command.id
        })
        try saveCatalog(reordered, changedIDs: changedIDs)
    }

    func deleteCustom(id: String) throws {
        guard let command = command(withID: id) else { throw CommandStoreError.commandNotFound }
        guard command.origin == .custom else { throw CommandStoreError.customCommandRequired }
        try CommandStorePersistence.remove(files(for: id), fileManager: fileManager)
        commands.removeAll { $0.id == id }
        loadedFileURLs.removeValue(forKey: id)
    }

    func resetFactory(id: String) throws {
        guard let factory = factoryDefaults.first(where: { $0.id == id }) else { throw CommandStoreError.factoryCommandRequired }
        try CommandStorePersistence.remove(files(for: id), fileManager: fileManager)
        commands = Self.sorted(commands.map { $0.id == id ? factory : $0 })
        loadedFileURLs.removeValue(forKey: id)
    }

    func resetAllFactoryCommands() throws {
        for factory in factoryDefaults {
            try CommandStorePersistence.remove(files(for: factory.id), fileManager: fileManager)
            loadedFileURLs.removeValue(forKey: factory.id)
        }
        let customCommands = commands.filter { $0.origin == .custom }
        commands = Self.sorted(factoryDefaults + customCommands)
    }
}

extension CommandStore {
    func files(for id: String) -> [URL] {
        let deterministic = CommandStorePersistence.fileURL(forID: id, in: directory)
        return (loadedFileURLs[id] ?? []) + [deterministic]
    }

    func nextOrder() -> Int {
        (commands.map(\.order).max() ?? -1) + 1
    }

    func availableDuplicateToken(for command: String) -> String {
        let base = String(command.dropFirst())
        var suffix = 1
        while true {
            let candidate = suffix == 1 ? "/\(base)-copy" : "/\(base)-copy-\(suffix)"
            if !commands.contains(where: { CommandValidator.canonical($0.command) == candidate }) {
                return candidate
            }
            suffix += 1
        }
    }

    func copy(_ command: SlashCommand, id: String, origin: SlashCommand.Origin, order: Int? = nil) -> SlashCommand {
        SlashCommand(
            id: id,
            command: command.command.trimmingCharacters(in: .whitespacesAndNewlines),
            aliases: command.aliases.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) },
            title: command.title,
            description: command.description,
            icon: command.icon,
            systemPrompt: command.systemPrompt,
            promptTemplate: command.promptTemplate,
            enabled: command.enabled,
            origin: origin,
            order: order ?? command.order
        )
    }
}
