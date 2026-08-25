import Foundation

public final class CommandRouter: @unchecked Sendable {
    private struct TokenCandidate {
        let command: SlashCommand
        let token: String
    }

    public static let shared = CommandRouter(catalog: CommandStore.shared)

    private let catalog: any CommandCatalogProviding

    public init(catalog: any CommandCatalogProviding) {
        self.catalog = catalog
    }

    public var commands: [SlashCommand] {
        catalog.resolvedCommands.filter(\.enabled).sorted {
            $0.order == $1.order ? $0.id < $1.id : $0.order < $1.order
        }
    }

    // Retained as a source-compatible name for the first public baseline.
    public var builtInCommands: [SlashCommand] {
        commands
    }

    public func matchCommands(query: String) -> [SlashCommand] {
        let query = CommandValidator.canonical(query)
        guard !query.isEmpty else { return commands }

        return commands.filter { command in
            command.command.lowercased().contains(query) ||
                command.aliases.contains { $0.lowercased().contains(query) } ||
                command.title.lowercased().contains(query) ||
                command.description.lowercased().contains(query)
        }
    }

    public func resolveCommand(from input: String) -> (SlashCommand?, String) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        for match in tokenMatches(in: trimmed) {
            return (match.command, match.argument)
        }
        return (nil, trimmed)
    }

    public func buildPrompt(
        command: SlashCommand?,
        rawInput: String,
        selectedText: String
    ) -> (systemPrompt: String, userPrompt: String) {
        let selectedCommand = command.flatMap { requested in
            commands.first { $0.id == requested.id }
        }
        let resolvedCommand = resolveCommand(from: rawInput).0
        let effectiveCommand = selectedCommand ?? resolvedCommand

        if let command = effectiveCommand {
            let argument = argument(for: command, in: rawInput)
            let targetText = !selectedText.isEmpty ? selectedText : argument
            let prompt = command.promptTemplate
                .replacingOccurrences(of: "{text}", with: targetText)
                .replacingOccurrences(of: "{arg}", with: argument.isEmpty ? "default" : argument)
            return (command.systemPrompt, prompt)
        }

        let systemPrompt = "You are an intelligent macOS AI assistant. Directly output the requested answer without filler or conversational preambles."
        let trimmedInput = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !selectedText.isEmpty && !trimmedInput.isEmpty {
            return (systemPrompt, "Selected Text:\n\(selectedText)\n\nInstruction: \(trimmedInput)")
        }
        return (systemPrompt, selectedText.isEmpty ? trimmedInput : selectedText)
    }

    private func argument(for command: SlashCommand, in input: String) -> String {
        tokenMatches(in: input).first(where: { $0.command.id == command.id })?.argument ?? ""
    }

    private func tokenMatches(in input: String) -> [(command: SlashCommand, argument: String)] {
        var candidates: [TokenCandidate] = []
        for command in commands {
            for token in [command.command] + command.aliases {
                candidates.append(TokenCandidate(command: command, token: token))
            }
        }
        candidates.sort {
            $0.token.count == $1.token.count
                ? $0.command.order < $1.command.order
                : $0.token.count > $1.token.count
        }

        var matches: [(command: SlashCommand, argument: String)] = []
        for candidate in candidates {
            guard let range = input.range(of: candidate.token, options: [.caseInsensitive, .anchored]) else { continue }
            let boundary = range.upperBound
            guard boundary == input.endIndex || input[boundary].isWhitespace else { continue }
            let argument = input[boundary...].trimmingCharacters(in: .whitespacesAndNewlines)
            matches.append((candidate.command, argument))
        }
        return matches
    }
}
