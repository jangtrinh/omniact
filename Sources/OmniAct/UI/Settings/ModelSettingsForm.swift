import SwiftUI

struct ModelSettingsForm: View {
    @ObservedObject var model: ModelSettingsViewModel
    @Binding var isEditingAPIKey: Bool

    var body: some View {
        SettingsCard {
            SettingsRow(title: "Provider", detail: providerDetail, showsSeparator: true) {
                SettingsMenuPicker(
                    selection: providerBinding,
                    options: LLMProviderType.allCases,
                    width: 165,
                    label: \.rawValue
                )
                .accessibilityLabel("Provider")
            }

            SettingsRow(
                title: model.provider == .ollama ? "Ollama host key" : "API key",
                detail: model.provider == .ollama
                    ? "Optional for a local server"
                    : "Stored securely in macOS Keychain",
                showsSeparator: true
            ) {
                HStack(spacing: 8) {
                    apiKeyField
                    Button(isEditingAPIKey ? "Done" : "Update…") {
                        isEditingAPIKey.toggle()
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.roundedRectangle(radius: 7))
                    .controlSize(.small)
                    .frame(width: 68, height: SettingsDesignMetrics.actionHeight)
                }
            }

            SettingsRow(title: "API base URL", showsSeparator: true) {
                TextField("https://…", text: $model.baseURL)
                    .settingsField(width: 270)
                    .accessibilityLabel("API base URL")
            }

            SettingsRow(title: "Selected model", showsSeparator: true) {
                modelMenu
            }

            SettingsRow(title: "Creativity", detail: "Balanced") {
                HStack(spacing: 6) {
                    Slider(value: roundedTemperature, in: 0...1)
                        .controlSize(.mini)
                        .frame(width: 168)
                        .accessibilityLabel("Creativity")
                        .accessibilityValue(temperatureLabel)
                    Text(temperatureLabel)
                        .font(.system(size: 11.5, weight: .medium).monospacedDigit())
                        .foregroundStyle(Color(red: 197 / 255, green: 197 / 255, blue: 202 / 255))
                        .frame(width: 26, alignment: .trailing)
                }
                .frame(width: 250, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private var apiKeyField: some View {
        if isEditingAPIKey {
            SecureField("Paste API key", text: $model.apiKey)
                .settingsField(width: 174)
                .accessibilityLabel("API key")
        } else {
            Text(model.apiKey.isEmpty ? "Not set" : "••••••••••••••••")
                .font(.system(size: 12))
                .foregroundStyle(
                    model.apiKey.isEmpty
                        ? SettingsPalette.secondary
                        : Color(red: 217 / 255, green: 217 / 255, blue: 221 / 255)
                )
                .padding(.horizontal, 10)
                .frame(
                    width: 174,
                    height: SettingsDesignMetrics.controlHeight,
                    alignment: .leading
                )
                .background(SettingsPalette.field, in: RoundedRectangle(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                }
                .accessibilityLabel(model.apiKey.isEmpty ? "API key not set" : "API key saved")
        }
    }

    private var modelMenu: some View {
        SettingsMenuPicker(
            selection: $model.modelName,
            options: displayedModels,
            width: 250,
            label: { $0 }
        )
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

    private var temperatureLabel: String {
        String(format: "%.1f", model.temperature)
    }
}

private extension View {
    func settingsField(width: CGFloat) -> some View {
        textFieldStyle(.plain)
            .font(.system(size: 12))
            .padding(.horizontal, 10)
            .frame(width: width, height: SettingsDesignMetrics.controlHeight)
            .background(SettingsPalette.field, in: RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            }
    }
}
