import Foundation

public extension CommandStore {
    @discardableResult
    func create(_ draft: SlashCommand) throws -> SlashCommand {
        guard command(withID: draft.id) == nil else { throw CommandStoreError.validation([.duplicateIdentifier]) }
        var command = copy(draft, id: draft.id.isEmpty ? UUID().uuidString.lowercased() : draft.id, origin: .custom)
        command.order = nextOrder()
        try saveCatalog(commands + [command])
        return command
    }

    func update(_ draft: SlashCommand) throws {
        guard let existing = command(withID: draft.id) else { throw CommandStoreError.commandNotFound }
        let updated = copy(draft, id: existing.id, origin: existing.origin, order: existing.order)
        try saveCatalog(commands.map { $0.id == existing.id ? updated : $0 })
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
        try saveCatalog(reordered)
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

private extension CommandStore {
    func saveCatalog(_ proposed: [SlashCommand]) throws {
        let sorted = Self.sorted(proposed)
        let issues = CommandValidator.validate(sorted)
        guard issues.isEmpty else { throw CommandStoreError.validation(issues) }

        var nextFiles = loadedFileURLs
        do {
            for command in sorted {
                if command.origin == .factory,
                   let factory = factoryDefaults.first(where: { $0.id == command.id }),
                   command == factory {
                    try CommandStorePersistence.remove(files(for: command.id), fileManager: fileManager)
                    nextFiles.removeValue(forKey: command.id)
                } else {
                    let file = try CommandStorePersistence.write(command, to: directory, fileManager: fileManager)
                    try CommandStorePersistence.remove(files(for: command.id).filter { $0 != file }, fileManager: fileManager)
                    nextFiles[command.id] = [file]
                }
            }
        } catch {
            throw CommandStoreError.persistence
        }
        commands = sorted
        loadedFileURLs = nextFiles
    }

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
