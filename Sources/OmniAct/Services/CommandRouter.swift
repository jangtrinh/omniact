import Foundation

public final class CommandRouter: @unchecked Sendable {
    public static let shared = CommandRouter()

    public private(set) var builtInCommands: [SlashCommand] = [
        SlashCommand(
            command: "/fix",
            title: "Fix Spelling & Grammar",
            description: "Correct grammar, punctuation, and typos seamlessly",
            icon: "wand.and.stars",
            systemPrompt: "You are an expert editor. Fix all spelling, grammar, and punctuation mistakes in the provided text. Return ONLY the corrected text without explanations or quotes.",
            promptTemplate: "Please correct the following text:\n\n{text}"
        ),
        SlashCommand(
            command: "/tone",
            title: "Rewrite Tone",
            description: "Change tone (formal, friendly, concise, persuasive)",
            icon: "bubble.left.and.bubble.right",
            systemPrompt: "You are a professional copywriter. Rewrite the provided text according to the requested tone. Return ONLY the rewritten text without preambles or notes.",
            promptTemplate: "Target Tone: {arg}\n\nOriginal Text:\n{text}"
        ),
        SlashCommand(
            command: "/translate",
            title: "Translate Language",
            description: "Translate text to English, Vietnamese, Japanese, etc.",
            icon: "globe",
            systemPrompt: "You are a professional translator. Translate the text accurately and naturally into the target language. Return ONLY the translated text without notes or quotes.",
            promptTemplate: "Target Language: {arg}\n\nText to translate:\n{text}"
        ),
        SlashCommand(
            command: "/summarize",
            title: "Summarize",
            description: "Condense text into clear key bullet points",
            icon: "list.bullet",
            systemPrompt: "You are an executive assistant. Summarize the text into concise, high-impact bullet points. Return ONLY the summary bullets.",
            promptTemplate: "Please summarize the following text:\n\n{text}"
        ),
        SlashCommand(
            command: "/draft",
            title: "Draft New Content",
            description: "Draft an email, message, reply, or outline",
            icon: "square.and.pencil",
            systemPrompt: "You are a helpful writing assistant. Draft high quality content based on the user's prompt. Output only the content directly.",
            promptTemplate: "Prompt: {arg}\nContext: {text}"
        ),
        SlashCommand(
            command: "/ask",
            title: "Ask AI / Freeform",
            description: "Ask any question or give custom instruction",
            icon: "questionmark.bubble",
            systemPrompt: "You are a direct, concise AI assistant. Follow instructions accurately without filler phrases.",
            promptTemplate: "Instruction: {arg}\n\nInput:\n{text}"
        )
    ]

    private init() {}

    public func matchCommands(query: String) -> [SlashCommand] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty {
            return builtInCommands
        }
        return builtInCommands.filter {
            $0.command.lowercased().contains(q) ||
            $0.title.lowercased().contains(q) ||
            $0.description.lowercased().contains(q)
        }
    }

    public func resolveCommand(from input: String) -> (SlashCommand?, String) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()

        // Exact prefix matching /cmd
        for cmd in builtInCommands {
            if trimmed.hasPrefix(cmd.command) {
                let rest = String(trimmed.dropFirst(cmd.command.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                return (cmd, rest)
            }
        }

        // Natural language matching without slash: fix, tone, translate, summarize
        if lower == "fix" || lower.hasPrefix("fix ") || lower == "grammar" || lower.hasPrefix("grammar ") {
            let cmd = builtInCommands.first { $0.command == "/fix" }
            let rest = (lower.hasPrefix("fix ") ? String(trimmed.dropFirst(4)) : (lower.hasPrefix("grammar ") ? String(trimmed.dropFirst(8)) : "")).trimmingCharacters(in: .whitespacesAndNewlines)
            return (cmd, rest)
        }
        if lower.hasPrefix("tone ") || lower.hasPrefix("rewrite ") {
            let cmd = builtInCommands.first { $0.command == "/tone" }
            let rest = String(trimmed.dropFirst(lower.hasPrefix("tone ") ? 5 : 8)).trimmingCharacters(in: .whitespacesAndNewlines)
            return (cmd, rest)
        }
        if lower.hasPrefix("translate ") {
            let cmd = builtInCommands.first { $0.command == "/translate" }
            let rest = String(trimmed.dropFirst(10)).trimmingCharacters(in: .whitespacesAndNewlines)
            return (cmd, rest)
        }
        if lower == "summarize" || lower.hasPrefix("summarize ") {
            let cmd = builtInCommands.first { $0.command == "/summarize" }
            let rest = lower.hasPrefix("summarize ") ? String(trimmed.dropFirst(10)).trimmingCharacters(in: .whitespacesAndNewlines) : ""
            return (cmd, rest)
        }

        return (nil, trimmed)
    }

    public func buildPrompt(
        command: SlashCommand?,
        rawInput: String,
        selectedText: String
    ) -> (systemPrompt: String, userPrompt: String) {
        let (resolvedCmd, arg) = resolveCommand(from: rawInput)
        let effectiveCmd = command ?? resolvedCmd

        if let cmd = effectiveCmd {
            let targetText: String
            if !selectedText.isEmpty {
                targetText = selectedText
            } else if !arg.isEmpty {
                targetText = arg
            } else {
                targetText = ""
            }

            var prompt = cmd.promptTemplate
            prompt = prompt.replacingOccurrences(of: "{text}", with: targetText)
            prompt = prompt.replacingOccurrences(of: "{arg}", with: arg.isEmpty ? "default" : arg)

            return (cmd.systemPrompt, prompt)
        } else {
            let sys = "You are an intelligent macOS AI assistant. Directly output the requested answer without filler or conversational preambles."
            let trimmedInput = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
            let user: String
            if !selectedText.isEmpty && !trimmedInput.isEmpty {
                user = "Selected Text:\n\(selectedText)\n\nInstruction: \(trimmedInput)"
            } else if !selectedText.isEmpty {
                user = selectedText
            } else {
                user = trimmedInput
            }
            return (sys, user)
        }
    }
}
