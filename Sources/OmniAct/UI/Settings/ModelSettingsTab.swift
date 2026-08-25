import SwiftUI

struct ModelSettingsTab: View {
    @StateObject private var model = ModelSettingsViewModel()
    @State private var isEditingAPIKey = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            SettingsPalette.content

            Text("Model provider")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(SettingsPalette.primary)
                .offset(x: 28, y: 22)

            Text("Choose where OmniAct runs requests and which model powers the HUD.")
                .font(.system(size: 12.5))
                .foregroundStyle(SettingsPalette.secondary)
                .offset(x: 28, y: 52)

            ModelSettingsForm(model: model, isEditingAPIKey: $isEditingAPIKey)
                .frame(
                    width: SettingsDesignMetrics.formWidth,
                    height: SettingsDesignMetrics.formHeight
                )
                .offset(x: 28, y: 92)

            SettingsCallout(
                icon: "shield.lefthalf.filled",
                title: "Credentials stay on this Mac",
                message: "API keys are never shown again after saving and are not included in logs."
            )
            .frame(width: SettingsDesignMetrics.formWidth, height: 58)
            .offset(x: 28, y: 410)

            Text(actionHint)
                .font(.system(size: 11))
                .foregroundStyle(actionHintColor)
                .lineLimit(1)
                .frame(width: 330, alignment: .leading)
                .offset(x: 28, y: 500)

            actionButtons.offset(x: 382, y: 492)
        }
        .frame(
            width: SettingsDesignMetrics.contentWidth,
            height: SettingsDesignMetrics.contentHeight
        )
        .onAppear { model.load() }
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button(model.isTesting ? "Testing…" : "Test Connection") {
                model.testConnection()
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle(radius: 7))
            .controlSize(.small)
            .frame(width: 116, height: SettingsDesignMetrics.actionHeight)
            .disabled(model.isTesting)

            Button("Save Changes") {
                model.save()
                isEditingAPIKey = false
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 7))
            .controlSize(.small)
            .tint(SettingsPalette.blue)
            .frame(width: 124, height: SettingsDesignMetrics.actionHeight)
        }
    }

    private var actionHint: String {
        model.result ?? "Validate this provider before saving."
    }

    private var actionHintColor: Color {
        guard let result = model.result else { return SettingsPalette.tertiary }
        if result.contains("✓") { return SettingsPalette.connected }
        if result.contains("✗") { return .orange }
        return SettingsPalette.tertiary
    }
}
