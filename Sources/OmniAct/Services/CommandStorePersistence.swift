import Foundation

struct CommandStoreLoadResult {
    let commands: [SlashCommand]
    let warnings: [String]
    let fileURLsByID: [String: [URL]]
}

enum CommandStorePersistence {
    static let maximumFileCount = 64
    static let maximumFileByteCount = 64 * 1_024
    static let maximumStableIDByteCount = CommandValidator.maximumStableIDByteCount

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
        guard let directoryValues = try? directory.resourceValues(forKeys: [.isDirectoryKey]),
              directoryValues.isDirectory == true else {
            return CommandStoreLoadResult(
                commands: factoryDefaults,
                warnings: ["Could not read command files. Check \(directory.path)."],
                fileURLsByID: [:]
            )
        }

        let discovered: (urls: [URL], exceededLimit: Bool)
        do {
            discovered = try commandFileURLs(in: directory, fileManager: fileManager)
        } catch {
            return CommandStoreLoadResult(
                commands: factoryDefaults,
                warnings: ["Could not read command files. Check \(directory.path)."],
                fileURLsByID: [:]
            )
        }

        var commands = factoryDefaults
        var warnings: [String] = []
        var fileURLsByID: [String: [URL]] = [:]
        let decoder = JSONDecoder()

        if discovered.exceededLimit {
            warnings.append("Skipped additional command files after the maximum of \(maximumFileCount) files in \(directory.path).")
        }

        for url in discovered.urls {
            guard let characteristics = fileCharacteristics(for: url) else {
                warnings.append(invalidFileWarning(in: directory))
                continue
            }
            guard characteristics.isRegularFile, !characteristics.isSymbolicLink else {
                warnings.append(invalidFileWarning(in: directory))
                continue
            }
            guard characteristics.byteCount <= maximumFileByteCount else {
                warnings.append("Skipped an invalid command file because it exceeds the maximum file size in \(directory.path).")
                continue
            }

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
                warnings.append(invalidFileWarning(in: directory))
            }
        }
        return CommandStoreLoadResult(commands: commands, warnings: warnings, fileURLsByID: fileURLsByID)
    }

    static func write(_ command: SlashCommand, to directory: URL, fileManager: FileManager) throws -> URL {
        guard command.id.lengthOfBytes(using: .utf8) <= maximumStableIDByteCount else {
            throw CommandStoreError.persistence
        }
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(command)
        guard data.count <= maximumFileByteCount else {
            throw CommandStoreError.persistence
        }
        let url = fileURL(forID: command.id, in: directory)
        if (try? fileManager.destinationOfSymbolicLink(atPath: url.path)) != nil {
            throw CommandStoreError.persistence
        }
        if fileManager.fileExists(atPath: url.path),
           let characteristics = fileCharacteristics(for: url),
           (!characteristics.isRegularFile || characteristics.isSymbolicLink) {
            throw CommandStoreError.persistence
        }
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

    static func candidateFileURLs(in directory: URL, fileManager: FileManager) throws -> [URL] {
        guard fileManager.fileExists(atPath: directory.path) else { return [] }
        let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey]
        let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: Array(resourceKeys),
            options: options
        ) else {
            throw CommandStoreError.persistence
        }
        var urls: [URL] = []
        while let url = enumerator.nextObject() as? URL {
            guard url.pathExtension.lowercased() == "json" else { continue }
            urls.append(url)
        }
        return urls.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private static func commandFileURLs(in directory: URL, fileManager: FileManager) throws -> (urls: [URL], exceededLimit: Bool) {
        let urls = try candidateFileURLs(in: directory, fileManager: fileManager)
        return (Array(urls.prefix(maximumFileCount)), urls.count > maximumFileCount)
    }

    private static func fileCharacteristics(for url: URL) -> (isRegularFile: Bool, isSymbolicLink: Bool, byteCount: Int)? {
        guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey]) else {
            return nil
        }
        return (values.isRegularFile == true, values.isSymbolicLink == true, values.fileSize ?? 0)
    }

    private static func expectedOrigin(for id: String, factoryDefaults: [SlashCommand]) -> SlashCommand.Origin {
        factoryDefaults.contains(where: { $0.id == id }) ? .factory : .custom
    }

    private static func hasOnlyCommandKeys(_ data: Data) -> Bool {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
        return Set(object.keys).isSubset(of: allowedKeys)
    }

    private static func invalidFileWarning(in directory: URL) -> String {
        "Skipped an invalid command file. Repair or remove it in \(directory.path)."
    }
}
