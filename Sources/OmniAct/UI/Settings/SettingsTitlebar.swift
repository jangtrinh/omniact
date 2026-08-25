import SwiftUI

struct SettingsTitlebarLeading: View {
    let title: String

    var body: some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(width: 118)
            SettingsAppIcon()
            Spacer()
                .frame(width: 26)
            Text(title)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(SettingsPalette.primary)
            Spacer(minLength: 0)
        }
        .frame(width: 340, height: SettingsDesignMetrics.toolbarHeight)
    }
}

struct SettingsTitlebarTrailing: View {
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(SettingsPalette.connected)
                .frame(width: 6, height: 6)
            Text("Connected")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(Color(red: 207 / 255, green: 207 / 255, blue: 211 / 255))
        }
        .frame(width: 96, height: 26)
        .background(Color.white.opacity(0.06), in: Capsule())
        .frame(width: 116, height: SettingsDesignMetrics.toolbarHeight, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Connected")
    }
}
