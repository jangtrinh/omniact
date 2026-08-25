import SwiftUI

public struct SettingsView: View {
    @State private var selectedTab = 0
    @State private var provider: LLMProviderType = .groq
    @State private var apiKey: String = ""
    @State private var baseURL: String = ""
    @State private var modelName: String = ""
    @State private var temperature: Double = 0.3
    @State private var isTesting: Bool = false
    @State private var isDetecting: Bool = false
    @State private var fetchedModels: [String] = []
    @State private var testResult: String? = nil
    @State private var isAccessibilityGranted: Bool = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header & Tab Bar
            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.accentColor)

                    Text("OmniAct Preferences")
                        .font(.system(size: 15, weight: .semibold))
                }

                Spacer()

                HStack(spacing: 4) {
                    SettingsTabPill(title: "AI Models", icon: "cpu", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    SettingsTabPill(title: "Permissions", icon: "lock.shield", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                    SettingsTabPill(title: "Commands", icon: "command", isSelected: selectedTab == 2) {
                        selectedTab = 2
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.04))

            Divider()
                .opacity(0.3)

            // MARK: - Tab Contents
            ScrollView {
                VStack(spacing: 18) {
                    if selectedTab == 0 {
                        modelsTab
                    } else if selectedTab == 1 {
                        permissionsTab
                    } else {
                        commandsTab
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 600, height: 530)
        .background(
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow)
        )
        .preferredColorScheme(.dark)
        .onAppear {
            loadSettings()
            checkAccessibility()
        }
    }

    // MARK: - 1. AI Models Tab
    private var modelsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Provider Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Provider")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                HStack(spacing: 6) {
                    ProviderSelectPill(title: "Groq (Free/Fast)", icon: "bolt.fill", isSelected: provider == .groq) {
                        setProvider(.groq)
                    }
                    ProviderSelectPill(title: "OpenAI", icon: "sparkle", isSelected: provider == .openai) {
                        setProvider(.openai)
                    }
                    ProviderSelectPill(title: "Ollama (Local)", icon: "laptopcomputer", isSelected: provider == .ollama) {
                        setProvider(.ollama)
                    }
                    ProviderSelectPill(title: "Custom", icon: "slider.horizontal.3", isSelected: provider == .custom) {
                        setProvider(.custom)
                    }
                }
            }

            // Credentials Card
            VStack(alignment: .leading, spacing: 12) {
                // API Key Field
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(provider == .ollama ? "Ollama Host Key (Optional)" : "API Key")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(action: autoDetectKey) {
                            HStack(spacing: 4) {
                                if isDetecting {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(isDetecting ? "Detecting..." : "Auto-Detect Models")
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        .disabled(isDetecting || apiKey.isEmpty)
                    }

                    SecureField(provider == .ollama ? "None required for local" : "Paste API key (e.g. gsk_... or sk-...)", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13, design: .monospaced))
                }

                // Base URL Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("API Base URL")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    TextField("https://...", text: $baseURL)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13, design: .monospaced))
                }

                // Model Name Selection
                VStack(alignment: .leading, spacing: 6) {
                    Text("Selected Model")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    if !fetchedModels.isEmpty {
                        Picker("", selection: $modelName) {
                            ForEach(fetchedModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                        .labelsHidden()
                    } else {
                        TextField("e.g. openai/gpt-oss-20b or llama-3.3-70b-versatile", text: $modelName)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13, design: .monospaced))
                    }
                }

                // Temperature Slider
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Creativity / Temperature: \(String(format: "%.1f", temperature))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                    }

                    Slider(value: $temperature, in: 0.0...1.0, step: 0.1)
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.04))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
            )

            // Action Buttons Row
            HStack(spacing: 10) {
                Button(action: saveSettings) {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save Settings")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button(action: testConnection) {
                    HStack(spacing: 5) {
                        if isTesting {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "play.fill")
                        }
                        Text(isTesting ? "Testing..." : "Test Connection")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(isTesting)

                Spacer()

                if let result = testResult {
                    Text(result)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(result.contains("✓") ? .green : .orange)
                }
            }
        }
    }

    // MARK: - 2. Permissions Tab
    private var permissionsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System Permissions")
                .font(.system(size: 14, weight: .semibold))

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: isAccessibilityGranted ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(isAccessibilityGranted ? .green : .orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("macOS Accessibility")
                            .font(.system(size: 13, weight: .medium))
                        Text(isAccessibilityGranted ? "Access granted. OmniAct can read selected text and replace inline." : "Permission required to read selected text across all apps.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if !isAccessibilityGranted {
                        Button(action: {
                            AccessibilityService.shared.requestAccessibilityPermission()
                            checkAccessibility()
                        }) {
                            Text("Grant Access")
                                .font(.system(size: 11.5, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider().opacity(0.2)

                HStack(spacing: 12) {
                    Image(systemName: "keyboard.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Global Shortcut")
                            .font(.system(size: 13, weight: .medium))
                        Text("Press Option + Space (⌥ Space) from any app to activate.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.04))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
            )
        }
    }

    // MARK: - 3. Commands Tab
    private var commandsTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Built-in Slash Commands")
                .font(.system(size: 14, weight: .semibold))

            VStack(spacing: 8) {
                ForEach(CommandRouter.shared.builtInCommands) { cmd in
                    HStack(spacing: 12) {
                        Image(systemName: cmd.icon)
                            .font(.system(size: 14))
                            .foregroundColor(.accentColor)
                            .frame(width: 22)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(cmd.command)
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                Text("• \(cmd.title)")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            Text(cmd.description)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Helpers
    private func setProvider(_ type: LLMProviderType) {
        provider = type
        baseURL = AppConfig.shared.getBaseURL(for: type)
        modelName = AppConfig.shared.getModelName(for: type)
        apiKey = AppConfig.shared.getAPIKey(for: type) ?? ""
        fetchedModels = []
    }

    private func loadSettings() {
        provider = AppConfig.shared.activeProvider
        baseURL = AppConfig.shared.getBaseURL(for: provider)
        modelName = AppConfig.shared.getModelName(for: provider)
        apiKey = AppConfig.shared.getAPIKey(for: provider) ?? ""
    }

    private func saveSettings() {
        AppConfig.shared.saveConfiguration(
            provider: provider,
            baseURL: baseURL,
            modelName: modelName,
            apiKey: apiKey.isEmpty ? nil : apiKey
        )
        testResult = "✓ Settings Saved (Active: \(modelName))"
    }

    private func checkAccessibility() {
        isAccessibilityGranted = AccessibilityService.shared.isAccessibilityGranted
    }

    private func autoDetectKey() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        isDetecting = true
        testResult = "Detecting models..."

        Task {
            if let models = try? await LLMClient.shared.fetchAvailableModels(baseURL: baseURL, apiKey: trimmedKey), !models.isEmpty {
                await MainActor.run {
                    self.fetchedModels = models
                    if !models.contains(self.modelName) {
                        self.modelName = models.contains("openai/gpt-oss-20b") ? "openai/gpt-oss-20b" : (models.first ?? self.modelName)
                    }
                    self.isDetecting = false
                    self.testResult = "✓ Validated (\(models.count) models available)"
                    self.saveSettings()
                }
                return
            }

            await MainActor.run {
                self.isDetecting = false
                self.testResult = "✗ Could not auto-detect with this key"
            }
        }
    }

    private func testConnection() {
        isTesting = true
        testResult = "Testing..."

        let config = LLMConfiguration(
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
                    config: config
                )
                var response = ""
                for try await chunk in stream {
                    response += chunk
                }
                await MainActor.run {
                    isTesting = false
                    testResult = "✓ Connected (\(response.trimmingCharacters(in: .whitespacesAndNewlines)))"
                }
            } catch {
                await MainActor.run {
                    isTesting = false
                    testResult = "✗ \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Settings Tab Pill
struct SettingsTabPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 11.5, weight: isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(isSelected ? 0.16 : 0.05))
            .cornerRadius(6)
            .foregroundColor(isSelected ? .white : .secondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Provider Select Pill
struct ProviderSelectPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10.5))
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.white.opacity(isSelected ? 0.18 : 0.06))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(isSelected ? 0.3 : 0.1), lineWidth: 0.5)
            )
            .foregroundColor(isSelected ? .white : .secondary)
        }
        .buttonStyle(.plain)
    }
}
