import SwiftUI

struct SettingsSidebar: View {
    @Binding var selection: SettingsSection

    var body: some View {
        VStack(spacing: 0) {
            SettingsPalette.sidebar
            .frame(height: SettingsDesignMetrics.toolbarHeight)

            ZStack(alignment: .topLeading) {
                SettingsPalette.sidebar
                Text("OMNIACT")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(SettingsPalette.tertiary)
                    .offset(x: 18, y: 18)
                    .accessibilityHidden(true)

                navigationButton(.models).offset(x: 14, y: 42)
                navigationButton(.permissions).offset(x: 14, y: 78)
                navigationButton(.commands).offset(x: 14, y: 114)

                Rectangle()
                    .fill(SettingsPalette.separator)
                    .frame(width: 204, height: 1)
                    .offset(x: 18, y: 160)

                Text("Local-first · Zero telemetry")
                    .font(.system(size: 11))
                    .foregroundStyle(SettingsPalette.tertiary)
                    .offset(x: 18, y: 178)

                Text("OmniAct 0.1")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Color(red: 102 / 255, green: 102 / 255, blue: 109 / 255))
                    .offset(x: 18, y: 514)
            }
            .frame(height: SettingsDesignMetrics.contentHeight)
        }
        .frame(
            width: SettingsDesignMetrics.sidebarWidth,
            height: SettingsDesignMetrics.windowHeight
        )
        .overlay(alignment: .trailing) {
            Rectangle().fill(SettingsPalette.separator).frame(width: 1)
        }
    }

    private func navigationButton(_ section: SettingsSection) -> some View {
        let isSelected = selection == section
        return Button {
            selection = section
        } label: {
            HStack(spacing: 8) {
                Image(systemName: section.icon)
                    .font(.system(size: section == .commands ? 15 : 13, weight: .medium))
                    .frame(width: 16, height: 16)
                Text(section.title)
                    .font(.system(size: 12.5, weight: isSelected ? .semibold : .regular))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .frame(
                width: SettingsDesignMetrics.navigationRowWidth,
                height: SettingsDesignMetrics.navigationRowHeight
            )
            .background(
                isSelected ? Color.white.opacity(0.10) : .clear,
                in: RoundedRectangle(cornerRadius: 7)
            )
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                }
            }
            .foregroundStyle(
                isSelected
                    ? SettingsPalette.primary
                    : Color(red: 193 / 255, green: 193 / 255, blue: 198 / 255)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(section.title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct SettingsAppIcon: View {
    var body: some View {
        Image(systemName: "sparkles")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(SettingsPalette.blue)
            .frame(width: 36, height: 36)
            .modifier(SettingsAppIconGlass())
            .accessibilityLabel("OmniAct")
    }
}

private struct SettingsAppIconGlass: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect(
                .regular
                    .tint(Color(red: 36 / 255, green: 38 / 255, blue: 42 / 255)),
                in: .circle
            )
        } else {
            content
                .background(Color(red: 36 / 255, green: 38 / 255, blue: 42 / 255), in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        }
    }
}
