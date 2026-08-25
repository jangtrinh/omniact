import Foundation

public struct SlashCommand: Identifiable, Codable, Sendable, Equatable {
    public enum Origin: String, Codable, Sendable {
        case factory
        case custom
    }

    public let id: String
    public var command: String
    public var aliases: [String]
    public var title: String
    public var description: String
    public var icon: String
    public var systemPrompt: String
    public var promptTemplate: String
    public var enabled: Bool
    public let origin: Origin
    public var order: Int

    public init(
        id: String,
        command: String,
        aliases: [String] = [],
        title: String,
        description: String,
        icon: String,
        systemPrompt: String,
        promptTemplate: String,
        enabled: Bool = true,
        origin: Origin,
        order: Int
    ) {
        self.id = id
        self.command = command
        self.aliases = aliases
        self.title = title
        self.description = description
        self.icon = icon
        self.systemPrompt = systemPrompt
        self.promptTemplate = promptTemplate
        self.enabled = enabled
        self.origin = origin
        self.order = order
    }

    public init(
        command: String,
        title: String,
        description: String,
        icon: String,
        systemPrompt: String,
        promptTemplate: String
    ) {
        self.init(
            id: command,
            command: command,
            title: title,
            description: description,
            icon: icon,
            systemPrompt: systemPrompt,
            promptTemplate: promptTemplate,
            origin: .factory,
            order: 0
        )
    }

    public static func newCustom(order: Int) -> SlashCommand {
        SlashCommand(
            id: UUID().uuidString.lowercased(),
            command: "/new-command",
            title: "New Command",
            description: "Describe what this command does",
            icon: "sparkles",
            systemPrompt: "You are a helpful assistant.",
            promptTemplate: "{text}",
            origin: .custom,
            order: order
        )
    }

    public var isFactory: Bool {
        origin == .factory
    }

    public var displayAliases: String {
        aliases.joined(separator: ", ")
    }
}
