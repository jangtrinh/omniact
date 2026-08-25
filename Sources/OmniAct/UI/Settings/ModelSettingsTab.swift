import SwiftUI

struct ModelSettingsTab: View {
    @StateObject private var model = ModelSettingsViewModel()
    @State private var isEditingAPIKey = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Model provider")
                    .font(.headline)
                Text("Choose where OmniAct runs requests and which model powers the HUD.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            configurationCard
            SettingsCallout(
                icon: "lock.shield.fill",
                title: "Credentials stay on this Mac",
                message: "API keys are never shown again after saving and are not included in logs."
            )
            actionBar
        }
        .onAppear { model.load() }
    }

    private var configurationCard: some View {
        SettingsCard {
            SettingsRow(title: "Provider", detail: providerDetail) {
                Picker("Provider", selection: providerBinding) {
                    ForEach(LLMProviderType.allCases, id: \.self) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .labelsHidden()
                .frame(width: 250)
            }
            Divider().padding(.leading, 16)
            SettingsRow(
                title: model.provider == .ollama ? "Ollama host key" : "API key",
                detail: model.provider == .ollama ? "Optional for a local server" : "Saved securely in Keychain"
            ) {
                HStack(spacing: 8) {
                    if isEditingAPIKey {
                        SecureField("Paste API key", text: $model.apiKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.body.monospaced())
                            .frame(width: 170)
                            .accessibilityLabel("API key")
                    } else {
                        Text(model.apiKey.isEmpty ? "Not set" : "••••••••••••")
                            .font(.body.monospaced())
                            .foregroundStyle(model.apiKey.isEmpty ? .secondary : .primary)
                            .frame(width: 170, alignment: .leading)
                            .padding(.horizontal, 7)
                            .frame(height: 22)
                            .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 5))
                            .accessibilityLabel(model.apiKey.isEmpty ? "API key not set" : "API key saved")
                    }
                    Button(isEditingAPIKey ? "Done" : "Update…") {
                        isEditingAPIKey.toggle()
                    }
                }
            }
            Divider().padding(.leading, 16)
            SettingsRow(title: "API base URL") {
                TextField("https://…", text: $model.baseURL)
                    .textFieldStyle(.roundedBorder)
                    .font(.body.monospaced())
                    .frame(width: 300)
                    .accessibilityLabel("API base URL")
            }
            Divider().padding(.leading, 16)
            SettingsRow(title: "Selected model") {
                modelField
            }
            Divider().padding(.leading, 16)
            SettingsRow(title: "Creativity", detail: "Lower values produce more consistent output") {
                HStack(spacing: 10) {
                    Slider(value: $model.temperature, in: 0...1, step: 0.1)
                        .frame(width: 180)
                        .accessibilityLabel("Creativity")
                        .accessibilityValue(temperatureLabel)
                    Text(temperatureLabel)
                        .font(.body.monospacedDigit())
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
    }

    @ViewBuilder
    private var modelField: some View {
        HStack(spacing: 8) {
            if model.fetchedModels.isEmpty {
                TextField("Model identifier", text: $model.modelName)
                    .textFieldStyle(.roundedBorder)
                    .font(.body.monospaced())
                    .frame(width: 210)
                    .accessibilityLabel("Selected model")
            } else {
                Picker("Selected model", selection: $model.modelName) {
                    ForEach(model.fetchedModels, id: \.self) { Text($0).tag($0) }
                }
                .labelsHidden()
                .frame(width: 210)
            }
            Button(model.isDetecting ? "Detecting…" : "Detect") {
                model.autoDetectModels()
            }
            .disabled(model.isDetecting || model.apiKey.isEmpty)
            .accessibilityHint("Fetches models available for this API key")
        }
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            if let result = model.result {
                Label(result, systemImage: resultIcon)
                    .font(.callout)
                    .foregroundStyle(resultColor)
                    .lineLimit(2)
            }
            Spacer()
            Button(model.isTesting ? "Testing…" : "Test Connection") {
                model.testConnection()
            }
            .disabled(model.isTesting)
            Button("Save Changes") {
                model.save()
                isEditingAPIKey = false
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var providerBinding: Binding<LLMProviderType> {
        Binding(get: { model.provider }, set: {
            isEditingAPIKey = false
            model.selectProvider($0)
        })
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

    private var temperatureLabel: String {
        String(format: "%.1f", model.temperature)
    }

    private var resultIcon: String {
        guard let result = model.result else { return "info.circle" }
        if result.contains("✓") { return "checkmark.circle.fill" }
        if result.contains("✗") { return "exclamationmark.triangle.fill" }
        return "clock"
    }

    private var resultColor: Color {
        guard let result = model.result else { return .secondary }
        if result.contains("✓") { return .green }
        if result.contains("✗") { return .orange }
        return .secondary
    }
}
