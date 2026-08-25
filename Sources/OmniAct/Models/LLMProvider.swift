import Foundation

public enum LLMProviderType: String, CaseIterable, Codable, Sendable {
    case groq = "Groq (Fastest)"
    case openai = "OpenAI (GPT-4o)"
    case anthropic = "Anthropic (Claude)"
    case ollama = "Ollama (Offline/Local)"
    case custom = "Custom OpenAI-Compatible"

    public var defaultBaseURL: String {
        switch self {
        case .groq:
            return "https://api.groq.com/openai/v1"
        case .openai:
            return "https://api.openai.com/v1"
        case .anthropic:
            return "https://api.anthropic.com/v1"
        case .ollama:
            return "http://localhost:11434/v1"
        case .custom:
            return "http://localhost:8000/v1"
        }
    }

    public var defaultModel: String {
        switch self {
        case .groq:
            return "llama-3.3-70b-versatile"
        case .openai:
            return "gpt-4o-mini"
        case .anthropic:
            return "claude-3-5-haiku-latest"
        case .ollama:
            return "llama3.2:3b"
        case .custom:
            return "default"
        }
    }

    public var popularModels: [String] {
        switch self {
        case .groq:
            return ["llama-3.3-70b-versatile", "llama-3.1-8b-instant", "llama3-70b-8192", "mixtral-8x7b-32768", "gemma2-9b-it"]
        case .openai:
            return ["gpt-4o-mini", "gpt-4o", "gpt-3.5-turbo"]
        case .anthropic:
            return ["claude-3-5-haiku-latest", "claude-3-5-sonnet-latest"]
        case .ollama:
            return ["llama3.2:3b", "gemma4:e4b", "gemma2:2b", "qwen2.5-coder", "mistral"]
        case .custom:
            return ["default"]
        }
    }
}

public struct LLMConfiguration: Codable, Sendable {
    public var providerType: LLMProviderType
    public var baseURL: String
    public var model: String
    public var apiKey: String?
    public var temperature: Double

    public init(
        providerType: LLMProviderType = .groq,
        baseURL: String? = nil,
        model: String? = nil,
        apiKey: String? = nil,
        temperature: Double = 0.3
    ) {
        self.providerType = providerType
        self.baseURL = baseURL ?? providerType.defaultBaseURL
        self.model = model ?? providerType.defaultModel
        self.apiKey = apiKey
        self.temperature = temperature
    }
}
