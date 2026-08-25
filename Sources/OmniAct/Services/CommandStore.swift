import Combine
import Foundation

@MainActor
public protocol CommandCatalogProviding: AnyObject {
    var resolvedCommands: [SlashCommand] { get }
}

public enum CommandStoreError: LocalizedError {
    case commandNotFound
    case factoryCommandRequired
    case customCommandRequired
    case validation([CommandValidationIssue])
    case fileLimitReached
    case persistence

    public var errorDescription: String? {
        switch self {
        case .commandNotFound:
            return "The command no longer exists. Reload the command library and try again."
        case .factoryCommandRequired:
            return "Only a factory command can be reset."
        case .customCommandRequired:
            return "Factory commands cannot be deleted. Reset them instead."
        case .validation(let issues):
            return issues.compactMap(\.errorDescription).joined(separator: " ")
        case .fileLimitReached:
            return "The command library already contains the maximum of 64 command files. Repair or remove a command file before adding another."
        case .persistence:
            return "Could not save the command. Check that the command directory is writable."
        }
    }
}

@MainActor
public final class CommandStore: ObservableObject, CommandCatalogProviding {
    public static let shared = CommandStore()

    @Published public internal(set) var commands: [SlashCommand]
    @Published public internal(set) var loadWarnings: [String] = []

    public let directory: URL
    let factoryDefaults: [SlashCommand]
    let fileManager: FileManager
    var loadedFileURLs: [String: [URL]] = [:]

    public static var defaultDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/omniact/commands", isDirectory: true)
    }

    public var resolvedCommands: [SlashCommand] {
        commands
    }

    public init(
        directory: URL? = nil,
        factoryDefaults: [SlashCommand] = FactoryCommandCatalog.commands,
        fileManager: FileManager = .default
    ) {
        self.directory = directory ?? Self.defaultDirectory
        self.factoryDefaults = Self.sorted(factoryDefaults)
        self.fileManager = fileManager
        self.commands = Self.sorted(factoryDefaults)
        reload()
    }

    @discardableResult
    public func reload() -> [String] {
        let loaded = CommandStorePersistence.load(
            from: directory,
            factoryDefaults: factoryDefaults,
            fileManager: fileManager
        )
        commands = Self.sorted(loaded.commands)
        loadedFileURLs = loaded.fileURLsByID
        loadWarnings = loaded.warnings
        return loaded.warnings
    }

    public func command(withID id: String) -> SlashCommand? {
        commands.first { $0.id == id }
    }

    public func isFactoryModified(_ command: SlashCommand) -> Bool {
        guard let factory = factoryDefaults.first(where: { $0.id == command.id }) else { return false }
        return factory != command
    }

    public func validationIssues(for draft: SlashCommand, replacing id: String? = nil) -> [CommandValidationIssue] {
        var proposed = commands.filter { $0.id != id }
        proposed.append(draft)
        return CommandValidator.validate(proposed)
    }

    public func fileURL(for command: SlashCommand) -> URL {
        CommandStorePersistence.fileURL(forID: command.id, in: directory)
    }

    static func sorted(_ commands: [SlashCommand]) -> [SlashCommand] {
        commands.sorted {
            $0.order == $1.order ? $0.id < $1.id : $0.order < $1.order
        }
    }
}
