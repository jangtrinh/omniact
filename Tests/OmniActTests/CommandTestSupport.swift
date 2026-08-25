import Foundation
@testable import OmniAct

func makeTemporaryCommandDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("OmniActCommandTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
}

func makeCustomCommand(
    token: String = "/custom-command",
    aliases: [String] = ["custom command"],
    title: String = "Custom Command",
    systemPrompt: String = "Custom system prompt",
    promptTemplate: String = "Input: {text}; Argument: {arg}",
    enabled: Bool = true
) -> SlashCommand {
    SlashCommand(
        id: UUID().uuidString.lowercased(),
        command: token,
        aliases: aliases,
        title: title,
        description: "A test command",
        icon: "sparkles",
        systemPrompt: systemPrompt,
        promptTemplate: promptTemplate,
        enabled: enabled,
        origin: .custom,
        order: 99
    )
}

@MainActor
final class MutableCommandCatalog: CommandCatalogProviding {
    var resolvedCommands: [SlashCommand]

    init(_ commands: [SlashCommand]) {
        resolvedCommands = commands
    }
}
