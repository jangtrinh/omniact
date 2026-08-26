import SwiftUI

struct ModelSettingsForm: View {
    private enum Field: Hashable {
        case apiKey
        case baseURL
    }

    @ObservedObject var model: ModelSettingsViewModel
    @Binding var isEditingAPIKey: Bool
    @FocusState private var focusedField: Field?

    var body: some View {
        Group {
            LabeledContent {
                Picker("Provider", selection: providerBinding) {
                    ForEach(LLMProviderType.allCases, id: \.self) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .labelsHidden()
                .frame(width: SettingsDesignMetrics.controlWidth)
            } label: {
                SettingsRowLabel("Provider", detail: providerDetail)
            }

            LabeledContent {
                HStack(spacing: 8) {
                    apiKeyField
                    Button(isEditingAPIKey ? "Done" : "Update…") {
                        isEditingAPIKey.toggle()
                    }
                    .accessibilityLabel(isEditingAPIKey ? "Finish editing API key" : "Update API key")
                }
            } label: {
                SettingsRowLabel(
                    model.provider == .ollama ? "Ollama host key" : "API key",
                    detail: model.provider == .ollama
                        ? "Optional for a local server"
                        : "Stored securely in macOS Keychain"
                )
            }

            LabeledContent("API base URL") {
                TextField("https://…", text: $model.baseURL)
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .frame(width: SettingsDesignMetrics.controlWidth)
                    .focused($focusedField, equals: .baseURL)
                    .accessibilityLabel("API base URL")
            }

            LabeledContent("Selected model") {
                modelPicker
            }

            LabeledContent {
                HStack(spacing: 8) {
                    Slider(value: roundedTemperature, in: 0...1, step: 0.1)
                        .accessibilityLabel("Creativity")
                        .accessibilityValue(temperatureLabel)
                    Text(temperatureLabel)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 28, alignment: .trailing)
                }
                .frame(width: SettingsDesignMetrics.controlWidth)
            } label: {
                SettingsRowLabel("Creativity", detail: creativityLabel)
            }
        }
        .onAppear {
            Task { @MainActor in
                await Task.yield()
                focusedField = nil
            }
        }
    }

    @ViewBuilder
    private var apiKeyField: some View {
        if isEditingAPIKey {
            SecureField("Paste API key", text: $model.apiKey)
                .labelsHidden()
                .textFieldStyle(.roundedBorder)
                .frame(width: 160)
                .focused($focusedField, equals: .apiKey)
                .accessibilityLabel("API key")
        } else {
            Text(model.apiKey.isEmpty ? "Not set" : "••••••••••••")
                .foregroundStyle(.secondary)
                .frame(width: 160, alignment: .leading)
                .accessibilityLabel(model.apiKey.isEmpty ? "API key not set" : "API key saved")
        }
    }

    private var modelPicker: some View {
        Picker("Selected model", selection: $model.modelName) {
            ForEach(displayedModels, id: \.self) { name in
                Text(name).tag(name)
            }
        }
        .labelsHidden()
        .frame(width: SettingsDesignMetrics.controlWidth)
        .contextMenu {
            Button("Detect Available Models", systemImage: "arrow.triangle.2.circlepath") {
                model.autoDetectModels()
            }
            .disabled(model.isDetecting || model.apiKey.isEmpty)
        }
        .accessibilityLabel("Selected model")
        .accessibilityValue(model.modelName)
        .accessibilityHint("Right-click to detect available models")
        .accessibilityAction(named: "Detect Available Models") {
            guard !model.isDetecting, !model.apiKey.isEmpty else { return }
            model.autoDetectModels()
        }
    }

    private var providerBinding: Binding<LLMProviderType> {
        Binding(get: { model.provider }, set: {
            isEditingAPIKey = false
            model.selectProvider($0)
        })
    }

    private var roundedTemperature: Binding<Double> {
        Binding(get: { model.temperature }, set: {
            model.temperature = ($0 * 10).rounded() / 10
        })
    }

    private var displayedModels: [String] {
        let names = [model.modelName] + model.fetchedModels
        return names.filter { !$0.isEmpty }.reduce(into: []) { result, name in
            if !result.contains(name) { result.append(name) }
        }
    }

    private var providerDetail: String {
        switch model.provider {
        case .groq: "Fast cloud inference"
        case .openai: "OpenAI hosted models"
        case .anthropic: "Anthropic Claude models"
        case .ollama: "Local, offline inference"
        case .custom: "OpenAI-compatible endpoint"
        }
    }

    private var creativityLabel: String {
        switch model.temperature {
        case ..<0.3: "Precise"
        case 0.7...: "Creative"
        default: "Balanced"
        }
    }

    private var temperatureLabel: String {
        String(format: "%.1f", model.temperature)
    }
}
