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
    @Published private(set) var status: ModelSettingsStatus = .idle

    func load() {
        provider = AppConfig.shared.activeProvider
        loadProviderValues()
        status = .idle
    }

    func selectProvider(_ type: LLMProviderType) {
        provider = type
        loadProviderValues()
        fetchedModels = []
        status = .idle
    }

    func save() {
        persistConfiguration()
        status = .saved
    }

    func markConfigurationChanged() {
        guard !isTesting, !isDetecting else { return }
        status = .idle
    }

    func autoDetectModels() {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        isDetecting = true
        status = .detectingModels
        let url = baseURL
        Task {
            if let models = try? await LLMClient.shared.fetchAvailableModels(baseURL: url, apiKey: key), !models.isEmpty {
                fetchedModels = models
                if !models.contains(modelName) {
                    modelName = models.contains("openai/gpt-oss-20b") ? "openai/gpt-oss-20b" : (models.first ?? modelName)
                }
                isDetecting = false
                persistConfiguration()
                status = .modelsDetected(count: models.count)
            } else {
                isDetecting = false
                status = .failed(message: "Could not detect models with this key")
            }
        }
    }

    func testConnection() {
        isTesting = true
        status = .testing(providerName: provider.rawValue)
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
                status = response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? .failed(message: "The provider returned an empty response")
                    : .connected
            } catch {
                isTesting = false
                status = .failed(message: error.localizedDescription)
            }
        }
    }

    private func persistConfiguration() {
        AppConfig.shared.saveConfiguration(
            provider: provider,
            baseURL: baseURL,
            modelName: modelName,
            apiKey: apiKey.isEmpty ? nil : apiKey
        )
    }

    private func loadProviderValues() {
        baseURL = AppConfig.shared.getBaseURL(for: provider)
        modelName = AppConfig.shared.getModelName(for: provider)
        apiKey = AppConfig.shared.getAPIKey(for: provider) ?? ""
    }
}
