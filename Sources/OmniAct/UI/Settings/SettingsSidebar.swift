import SwiftUI

struct SettingsSidebar: View {
    @Binding var selection: SettingsSection

    var body: some View {
        List(selection: $selection) {
            ForEach(SettingsSection.allCases) { section in
                Label(section.title, systemImage: section.icon)
                    .tag(section)
                    .accessibilityLabel(section.title)
            }
        }
        .listStyle(.sidebar)
        .accessibilityLabel("Settings sections")
    }
}
