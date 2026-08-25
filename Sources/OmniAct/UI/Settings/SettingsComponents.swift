import SwiftUI

struct SettingsSidebar: View {
    @Binding var selection: SettingsSection

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("OMNIACT")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .accessibilityHidden(true)
            VStack(spacing: 4) {
                ForEach(SettingsSection.allCases) { section in
                    navigationButton(for: section)
                }
            }
            Spacer()
            Text("OmniAct 0.1")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 8)
        }
        .padding(16)
        .frame(width: 240)
        .background(Color(nsColor: .underPageBackgroundColor).opacity(0.5))
    }

    private func navigationButton(for section: SettingsSection) -> some View {
        let isSelected = selection == section
        return Button {
            selection = section
        } label: {
            HStack(spacing: 11) {
                Image(systemName: section.icon)
                    .frame(width: 18)
                Text(section.title)
                    .font(.body.weight(isSelected ? .semibold : .regular))
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
            .background(
                isSelected ? Color.accentColor.opacity(0.22) : Color.clear,
                in: RoundedRectangle(cornerRadius: 8)
            )
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(section.title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Opens \(section.title) settings")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

}

struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.62))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }
}

struct SettingsRow<Content: View>: View {
    let title: String
    let detail: String?
    @ViewBuilder let content: Content

    init(title: String, detail: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.detail = detail
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 16)
            content
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 60)
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
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                if let title {
                    Text(title)
                        .font(.callout.weight(.medium))
                }
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }
}
