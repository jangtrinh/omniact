import Foundation

struct CommandStoreLoadResult {
    let commands: [SlashCommand]
    let warnings: [String]
    let fileURLsByID: [String: [URL]]
}

enum CommandStorePersistence {
    private static let allowedKeys: Set<String> = [
        "id", "command", "aliases", "title", "description", "icon", "systemPrompt",
        "promptTemplate", "enabled", "origin", "order"
    ]

    static func load(
        from directory: URL,
        factoryDefaults: [SlashCommand],
        fileManager: FileManager
    ) -> CommandStoreLoadResult {
        guard fileManager.fileExists(atPath: directory.path) else {
            return CommandStoreLoadResult(commands: factoryDefaults, warnings: [], fileURLsByID: [:])
        }

        let urls: [URL]
        do {
            urls = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ).filter { $0.pathExtension.lowercased() == "json" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
        } catch {
            return CommandStoreLoadResult(
                commands: factoryDefaults,
                warnings: ["Could not read command files. Check (directory.path)."],
                fileURLsByID: [:]
            )
        }

        var commands = factoryDefaults
        var warnings: [String] = []
        var fileURLsByID: [String: [URL]] = [:]
        let decoder = JSONDecoder()

        for url in urls {
            do {
                let data = try Data(contentsOf: url)
                guard hasOnlyCommandKeys(data), let decoded = try? decoder.decode(SlashCommand.self, from: data) else {
                    throw CommandStoreError.persistence
                }
                guard decoded.origin == expectedOrigin(for: decoded.id, factoryDefaults: factoryDefaults) else {
                    throw CommandStoreError.persistence
                }

                var proposed = commands
                if let index = proposed.firstIndex(where: { $0.id == decoded.id }) {
                    proposed[index] = decoded
                } else {
                    proposed.append(decoded)
                }
                guard CommandValidator.validate(proposed).isEmpty else {
                    throw CommandStoreError.validation([])
                }

                commands = proposed
                fileURLsByID[decoded.id, default: []].append(url)
            } catch {
                warnings.append("Skipped an invalid command file. Repair or remove it in (directory.path).")
            }
        }
        return CommandStoreLoadResult(commands: commands, warnings: warnings, fileURLsByID: fileURLsByID)
    }

    static func write(_ command: SlashCommand, to directory: URL, fileManager: FileManager) throws -> URL {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(command)
        let url = fileURL(forID: command.id, in: directory)
        try data.write(to: url, options: .atomic)
        return url
    }

    static func remove(_ urls: [URL], fileManager: FileManager) throws {
        for url in Set(urls) where fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    static func fileURL(forID id: String, in directory: URL) -> URL {
        let hexID = id.utf8.map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent("command-\(hexID).json", isDirectory: false)
    }

    private static func expectedOrigin(for id: String, factoryDefaults: [SlashCommand]) -> SlashCommand.Origin {
        factoryDefaults.contains(where: { $0.id == id }) ? .factory : .custom
    }

    private static func hasOnlyCommandKeys(_ data: Data) -> Bool {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
        return Set(object.keys).isSubset(of: allowedKeys)
    }
}
