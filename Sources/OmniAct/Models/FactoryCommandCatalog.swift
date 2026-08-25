import Foundation

public enum FactoryCommandCatalog {
    public static let commands: [SlashCommand] = [
        SlashCommand(
            id: "factory.fix",
            command: "/fix",
            aliases: ["fix", "grammar"],
            title: "Fix Spelling & Grammar",
            description: "Correct grammar, punctuation, and typos seamlessly",
            icon: "wand.and.stars",
            systemPrompt: "You are an expert editor. Fix all spelling, grammar, and punctuation mistakes in the provided text. Return ONLY the corrected text without explanations or quotes.",
            promptTemplate: "Please correct the following text:\n\n{text}",
            origin: .factory,
            order: 0
        ),
        SlashCommand(
            id: "factory.tone",
            command: "/tone",
            aliases: ["tone", "rewrite"],
            title: "Rewrite Tone",
            description: "Change tone (formal, friendly, concise, persuasive)",
            icon: "bubble.left.and.bubble.right",
            systemPrompt: "You are a professional copywriter. Rewrite the provided text according to the requested tone. Return ONLY the rewritten text without preambles or notes.",
            promptTemplate: "Target Tone: {arg}\n\nOriginal Text:\n{text}",
            origin: .factory,
            order: 1
        ),
        SlashCommand(
            id: "factory.translate",
            command: "/translate",
            aliases: ["translate"],
            title: "Translate Language",
            description: "Translate text to English, Vietnamese, Japanese, etc.",
            icon: "globe",
            systemPrompt: "You are a professional translator. Translate the text accurately and naturally into the target language. Return ONLY the translated text without notes or quotes.",
            promptTemplate: "Target Language: {arg}\n\nText to translate:\n{text}",
            origin: .factory,
            order: 2
        ),
        SlashCommand(
            id: "factory.summarize",
            command: "/summarize",
            aliases: ["summarize"],
            title: "Summarize",
            description: "Condense text into clear key bullet points",
            icon: "list.bullet",
            systemPrompt: "You are an executive assistant. Summarize the text into concise, high-impact bullet points. Return ONLY the summary bullets.",
            promptTemplate: "Please summarize the following text:\n\n{text}",
            origin: .factory,
            order: 3
        ),
        SlashCommand(
            id: "factory.draft",
            command: "/draft",
            title: "Draft New Content",
            description: "Draft an email, message, reply, or outline",
            icon: "square.and.pencil",
            systemPrompt: "You are a helpful writing assistant. Draft high quality content based on the user's prompt. Output only the content directly.",
            promptTemplate: "Prompt: {arg}\nContext: {text}",
            origin: .factory,
            order: 4
        ),
        SlashCommand(
            id: "factory.ask",
            command: "/ask",
            title: "Ask AI / Freeform",
            description: "Ask any question or give custom instruction",
            icon: "questionmark.bubble",
            systemPrompt: "You are a direct, concise AI assistant. Follow instructions accurately without filler phrases.",
            promptTemplate: "Instruction: {arg}\n\nInput:\n{text}",
            origin: .factory,
            order: 5
        )
    ]

    public static func command(withID id: String) -> SlashCommand? {
        commands.first { $0.id == id }
    }
}
