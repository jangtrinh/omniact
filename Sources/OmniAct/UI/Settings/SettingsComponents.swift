import SwiftUI

struct SettingsToolbar: View {
    let title: String

    var body: some View {
        SettingsPalette.content
            .accessibilityLabel(title)
        .frame(width: SettingsDesignMetrics.contentWidth, height: SettingsDesignMetrics.toolbarHeight)
        .overlay(alignment: .bottom) {
            Rectangle().fill(SettingsPalette.separator).frame(height: 1)
        }
    }
}

struct SettingsMenuPicker<Option: Hashable>: View {
    @Binding var selection: Option
    let options: [Option]
    let width: CGFloat
    let label: (Option) -> String

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(label(option)) {
                    selection = option
                }
            }
        } label: {
            Color.clear
                .frame(width: width, height: SettingsDesignMetrics.controlHeight)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .frame(width: width, height: SettingsDesignMetrics.controlHeight)
        .background(SettingsPalette.control, in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            HStack(spacing: 6) {
                Text(label(selection))
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundStyle(SettingsPalette.secondary)
            }
            .padding(.horizontal, 10)
            .frame(width: width, height: SettingsDesignMetrics.controlHeight)
            .allowsHitTesting(false)

            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        }
        .contentShape(Rectangle())
        .accessibilityValue(label(selection))
    }
}

struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .background(SettingsPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(SettingsPalette.border, lineWidth: 0.5)
            }
    }
}

struct SettingsRow<Content: View>: View {
    let title: String
    let detail: String?
    let showsSeparator: Bool
    @ViewBuilder let content: Content

    init(
        title: String,
        detail: String? = nil,
        showsSeparator: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.detail = detail
        self.showsSeparator = showsSeparator
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SettingsPalette.label)
                if let detail {
                    Text(detail)
                        .font(.system(size: 10.5))
                        .foregroundStyle(Color(red: 129 / 255, green: 129 / 255, blue: 135 / 255))
                }
            }
            Spacer(minLength: 8)
            content
        }
        .padding(.horizontal, 16)
        .frame(height: 60)
        .overlay(alignment: .bottom) {
            if showsSeparator {
                Rectangle().fill(SettingsPalette.separator).frame(height: 1)
            }
        }
    }
}

struct SettingsCallout: View {
    let icon: String
    let title: String?
    let message: String

    init(icon: String, title: String? = nil, message: String) {
        self.icon = icon
        self.title = title
        self.message = message
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SettingsPalette.blue)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 3) {
                if let title {
                    Text(title)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(Color(red: 221 / 255, green: 238 / 255, blue: 1))
                }
                Text(message)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(red: 146 / 255, green: 184 / 255, blue: 216 / 255))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SettingsPalette.blue.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(SettingsPalette.blue.opacity(0.16), lineWidth: 0.5)
        }
    }
}
