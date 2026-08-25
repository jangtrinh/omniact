import Foundation

extension CommandStore {
    func saveCatalog(_ proposed: [SlashCommand], changedIDs: Set<String>) throws {
        let sorted = Self.sorted(proposed)
        let issues = CommandValidator.validate(sorted)
        guard issues.isEmpty else { throw CommandStoreError.validation(issues) }
        let changedCommands = sorted.filter { changedIDs.contains($0.id) }
        try ensureCandidateCapacity(for: changedCommands)

        var nextFiles = loadedFileURLs
        do {
            for command in changedCommands {
                if shouldRemoveFactoryOverride(for: command) {
                    try CommandStorePersistence.remove(files(for: command.id), fileManager: fileManager)
                    nextFiles.removeValue(forKey: command.id)
                } else {
                    let file = try CommandStorePersistence.write(command, to: directory, fileManager: fileManager)
                    try CommandStorePersistence.remove(files(for: command.id).filter { $0 != file }, fileManager: fileManager)
                    nextFiles[command.id] = [file]
                }
            }
        } catch let error as CommandStoreError {
            throw error
        } catch {
            throw CommandStoreError.persistence
        }
        commands = sorted
        loadedFileURLs = nextFiles
    }

    func ensureCandidateCapacity(for commands: [SlashCommand]) throws {
        var candidatePaths = Set(try CommandStorePersistence.candidateFileURLs(
            in: directory,
            fileManager: fileManager
        ).map(\.path))

        for command in commands {
            let destination = CommandStorePersistence.fileURL(forID: command.id, in: directory).path
            let replacedPaths = files(for: command.id).map(\.path).filter { $0 != destination }
            candidatePaths.subtract(replacedPaths)
            if shouldRemoveFactoryOverride(for: command) {
                candidatePaths.remove(destination)
            } else if !candidatePaths.contains(destination) {
                guard candidatePaths.count < CommandStorePersistence.maximumFileCount else {
                    throw CommandStoreError.fileLimitReached
                }
                candidatePaths.insert(destination)
            }
        }
    }

    func shouldRemoveFactoryOverride(for command: SlashCommand) -> Bool {
        guard command.origin == .factory,
              let factory = factoryDefaults.first(where: { $0.id == command.id }) else {
            return false
        }
        return command == factory
    }
}
