import Foundation

public enum CommandValidationIssue: Error, Equatable, Sendable, LocalizedError {
    case emptyIdentifier
    case duplicateIdentifier
    case invalidSlashToken
    case emptyTitle
    case emptySystemPrompt
    case emptyPromptTemplate
    case emptyAlias
    case duplicateSlashToken
    case aliasCollision
    case unsupportedPlaceholder

    public var errorDescription: String? {
        switch self {
        case .emptyIdentifier:
            return "Each command must have a stable ID."
        case .duplicateIdentifier:
            return "Each command must have a unique stable ID."
        case .invalidSlashToken:
            return "Slash command must start with / and use lowercase letters, numbers, or hyphens."
        case .emptyTitle:
            return "Title cannot be empty."
        case .emptySystemPrompt:
            return "System prompt cannot be empty."
        case .emptyPromptTemplate:
            return "Prompt template cannot be empty."
        case .emptyAlias:
            return "Aliases cannot be empty."
        case .duplicateSlashToken:
            return "Slash command tokens must be unique, ignoring case."
        case .aliasCollision:
            return "An alias collides with another command or alias."
        case .unsupportedPlaceholder:
            return "Only {text} and {arg} placeholders are supported."
        }
    }
}

public enum CommandValidator {
    public static func validate(_ commands: [SlashCommand]) -> [CommandValidationIssue] {
        var issues: [CommandValidationIssue] = []
        var identifiers = Set<String>()
        var tokens = Set<String>()

        for command in commands {
            if command.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                append(.emptyIdentifier, to: &issues)
            }
            if !identifiers.insert(command.id).inserted {
                append(.duplicateIdentifier, to: &issues)
            }
            if !isValidSlashToken(command.command) {
                append(.invalidSlashToken, to: &issues)
            }
            if command.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                append(.emptyTitle, to: &issues)
            }
            if command.systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                append(.emptySystemPrompt, to: &issues)
            }
            if command.promptTemplate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                append(.emptyPromptTemplate, to: &issues)
            }
            if hasUnsupportedPlaceholder(in: command.systemPrompt) ||
                hasUnsupportedPlaceholder(in: command.promptTemplate) {
                append(.unsupportedPlaceholder, to: &issues)
            }

            let token = canonical(command.command)
            if !tokens.insert(token).inserted {
                append(.duplicateSlashToken, to: &issues)
            }
        }

        let primaryTokens = Set(commands.map { canonical($0.command) })
        var aliases = Set<String>()
        for command in commands {
            for alias in command.aliases {
                let normalized = canonical(alias)
                if normalized.isEmpty {
                    append(.emptyAlias, to: &issues)
                } else if primaryTokens.contains(normalized) || !aliases.insert(normalized).inserted {
                    append(.aliasCollision, to: &issues)
                }
            }
        }
        return issues
    }

    public static func isValidSlashToken(_ value: String) -> Bool {
        let token = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard token.first == "/", token.count > 1 else { return false }

        var previousWasHyphen = false
        for character in token.dropFirst() {
            guard character.isASCII else { return false }
            if character == "-" {
                if previousWasHyphen { return false }
                previousWasHyphen = true
            } else if ("a"..."z").contains(character) || ("0"..."9").contains(character) {
                previousWasHyphen = false
            } else {
                return false
            }
        }
        return !previousWasHyphen
    }

    public static func canonical(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func append(_ issue: CommandValidationIssue, to issues: inout [CommandValidationIssue]) {
        if !issues.contains(issue) {
            issues.append(issue)
        }
    }

    private static func hasUnsupportedPlaceholder(in value: String) -> Bool {
        var remaining = value[...]
        while let opening = remaining.firstIndex(of: "{") {
            guard let closing = remaining[opening...].firstIndex(of: "}") else { return true }
            let placeholder = String(remaining[opening...closing])
            if placeholder != "{text}" && placeholder != "{arg}" {
                return true
            }
            remaining = remaining[remaining.index(after: closing)...]
        }
        return remaining.contains("}")
    }
}
