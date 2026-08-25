import Combine
import Foundation

@MainActor
final class ModelSettingsViewModel: ObservableObject {
    @Published var provider: LLMProviderType = .groq
    @Published var apiKey = ""
    @Published var baseURL = ""
    @Published var modelName = ""
    @Published var temperature = 0.3
    @Published var isTesting = false
    @Published var isDetecting = false
    @Published var fetchedModels: [String] = []
    @Published var result: String?

    func load() {
        provider = AppConfig.shared.activeProvider
        loadProviderValues()
    }

    func selectProvider(_ type: LLMProviderType) {
        provider = type
        loadProviderValues()
        fetchedModels = []
    }

    func save() {
        AppConfig.shared.saveConfiguration(
            provider: provider,
            baseURL: baseURL,
            modelName: modelName,
            apiKey: apiKey.isEmpty ? nil : apiKey
        )
        result = "✓ Settings Saved (Active: \(modelName))"
    }

    func autoDetectModels() {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        isDetecting = true
        result = "Detecting models..."
        let url = baseURL
        Task {
            if let models = try? await LLMClient.shared.fetchAvailableModels(baseURL: url, apiKey: key), !models.isEmpty {
                fetchedModels = models
                if !models.contains(modelName) {
                    modelName = models.contains("openai/gpt-oss-20b") ? "openai/gpt-oss-20b" : (models.first ?? modelName)
                }
                isDetecting = false
                result = "✓ Validated (\(models.count) models available)"
                save()
            } else {
                isDetecting = false
                result = "✗ Could not auto-detect with this key"
            }
        }
    }

    func testConnection() {
        isTesting = true
        result = "Testing..."
        let configuration = LLMConfiguration(
            providerType: provider,
            baseURL: baseURL,
            model: modelName,
            apiKey: apiKey.isEmpty ? nil : apiKey,
            temperature: temperature
        )
        Task {
            do {
                let stream = LLMClient.shared.streamCompletion(
                    prompt: "Ping test. Reply with 'OK'.",
                    systemPrompt: "You are a test assistant.",
                    config: configuration
                )
                var response = ""
                for try await chunk in stream {
                    response += chunk
                }
                isTesting = false
                result = "✓ Connected (\(response.trimmingCharacters(in: .whitespacesAndNewlines)))"
            } catch {
                isTesting = false
                result = "✗ \(error.localizedDescription)"
            }
        }
    }

    private func loadProviderValues() {
        baseURL = AppConfig.shared.getBaseURL(for: provider)
        modelName = AppConfig.shared.getModelName(for: provider)
        apiKey = AppConfig.shared.getAPIKey(for: provider) ?? ""
    }
}
