import SwiftUI

public struct SettingsView: View {
    @State private var selectedTab = 0

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.3)
            ScrollView {
                tabContent
                    .padding(20)
            }
        }
        .frame(width: 600, height: 530)
        .background(VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow))
        .preferredColorScheme(.dark)
    }

    private var header: some View {
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
                SettingsTabPill(title: "AI Models", icon: "cpu", isSelected: selectedTab == 0) { selectedTab = 0 }
                SettingsTabPill(title: "Permissions", icon: "lock.shield", isSelected: selectedTab == 1) { selectedTab = 1 }
                SettingsTabPill(title: "Commands", icon: "command", isSelected: selectedTab == 2) { selectedTab = 2 }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.04))
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:
            ModelSettingsTab()
        case 1:
            PermissionsSettingsTab()
        default:
            CommandLibraryView()
        }
    }
}
