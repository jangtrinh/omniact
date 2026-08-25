import SwiftUI

struct ModelSettingsTab: View {
    @StateObject private var model = ModelSettingsViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            providerPicker
            configurationCard
            actions
        }
        .onAppear { model.load() }
    }

    private var providerPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Provider").font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
            HStack(spacing: 6) {
                ProviderSelectPill(title: "Groq (Free/Fast)", icon: "bolt.fill", isSelected: model.provider == .groq) { model.selectProvider(.groq) }
                ProviderSelectPill(title: "OpenAI", icon: "sparkle", isSelected: model.provider == .openai) { model.selectProvider(.openai) }
                ProviderSelectPill(title: "Ollama (Local)", icon: "laptopcomputer", isSelected: model.provider == .ollama) { model.selectProvider(.ollama) }
                ProviderSelectPill(title: "Custom", icon: "slider.horizontal.3", isSelected: model.provider == .custom) { model.selectProvider(.custom) }
            }
        }
    }

    private var configurationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(model.provider == .ollama ? "Ollama Host Key (Optional)" : "API Key")
                    .font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
                Spacer()
                Button(model.isDetecting ? "Detecting..." : "Auto-Detect Models") { model.autoDetectModels() }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.accentColor)
                    .disabled(model.isDetecting || model.apiKey.isEmpty)
            }
            SecureField(model.provider == .ollama ? "None required for local" : "Paste API key", text: $model.apiKey)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13, design: .monospaced))
            labelledField("API Base URL", text: $model.baseURL, placeholder: "https://...")
            VStack(alignment: .leading, spacing: 6) {
                Text("Selected Model").font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
                if model.fetchedModels.isEmpty {
                    TextField("e.g. llama-3.3-70b-versatile", text: $model.modelName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13, design: .monospaced))
                } else {
                    Picker("", selection: $model.modelName) {
                        ForEach(model.fetchedModels, id: \.self) { Text($0).tag($0) }
                    }
                    .labelsHidden()
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Creativity / Temperature: \(String(format: "%.1f", model.temperature))")
                    .font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
                Slider(value: $model.temperature, in: 0...1, step: 0.1)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5))
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button("Save Settings") { model.save() }.buttonStyle(.borderedProminent)
            Button(model.isTesting ? "Testing..." : "Test Connection") { model.testConnection() }
                .buttonStyle(.bordered)
                .disabled(model.isTesting)
            Spacer()
            if let result = model.result {
                Text(result).font(.system(size: 11.5, weight: .medium)).foregroundColor(result.contains("✓") ? .green : .orange)
            }
        }
    }

    private func labelledField(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
            TextField(placeholder, text: text).textFieldStyle(.roundedBorder).font(.system(size: 13, design: .monospaced))
        }
    }
}
