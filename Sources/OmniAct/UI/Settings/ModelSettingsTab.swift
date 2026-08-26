import AppKit
import SwiftUI

struct ModelSettingsTab: View {
    @StateObject private var model = ModelSettingsViewModel()
    @State private var isEditingAPIKey = false

    var body: some View {
        Form {
            Section {
                ModelSettingsForm(model: model, isEditingAPIKey: $isEditingAPIKey)
            } header: {
                Text("Model provider")
            } footer: {
                Text("API keys stay in macOS Keychain. Cloud requests go only to the selected provider.")
            }
        }
        .formStyle(.grouped)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actionBar
        }
        .onAppear { model.load() }
        .onChange(of: model.apiKey) { _, _ in model.markConfigurationChanged() }
        .onChange(of: model.baseURL) { _, _ in model.markConfigurationChanged() }
        .onChange(of: model.modelName) { _, _ in model.markConfigurationChanged() }
        .onChange(of: model.temperature) { _, _ in model.markConfigurationChanged() }
    }

    private var actionBar: some View {
        VStack(spacing: 0) {
            Divider()
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    status
                    Spacer(minLength: 12)
                    actions
                }
                VStack(alignment: .leading, spacing: 8) {
                    status
                    HStack {
                        Spacer()
                        actions
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var status: some View {
        ModelSettingsStatusView(status: model.status)
            .frame(minHeight: 20)
    }

    private var actions: some View {
        HStack(spacing: 8) {
            Button("Test Connection") {
                model.testConnection()
            }
            .disabled(model.isTesting)
            .accessibilityLabel(model.isTesting ? "Testing connection" : "Test Connection")

            Button("Save Changes") {
                model.save()
                isEditingAPIKey = false
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .accessibilityLabel("Save Changes")
        }
    }
}

private struct ModelSettingsStatusView: View {
    let status: ModelSettingsStatus

    var body: some View {
        let presentation = status.presentation
        HStack(spacing: 7) {
            if presentation.showsProgress {
                ProgressView()
                    .controlSize(.small)
            } else if let symbol = presentation.symbol {
                Image(systemName: symbol)
                    .foregroundStyle(toneColor)
                    .accessibilityHidden(true)
            }
            Text(presentation.message)
                .font(.callout)
                .foregroundStyle(toneColor)
                .lineLimit(2)
        }
        .accessibilityElement(children: .combine)
    }

    private var toneColor: Color {
        switch status.presentation.tone {
        case .secondary: .secondary
        case .success: .green
        case .warning: .orange
        }
    }
}
