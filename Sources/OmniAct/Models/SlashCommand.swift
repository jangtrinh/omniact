import Foundation

public struct SlashCommand: Identifiable, Sendable, Equatable {
    public let id: String
    public let command: String
    public let title: String
    public let description: String
    public let icon: String
    public let systemPrompt: String
    public let promptTemplate: String

    public init(
        command: String,
        title: String,
        description: String,
        icon: String,
        systemPrompt: String,
        promptTemplate: String
    ) {
        self.id = command
        self.command = command
        self.title = title
        self.description = description
        self.icon = icon
        self.systemPrompt = systemPrompt
        self.promptTemplate = promptTemplate
    }
}
