import SwiftUI

enum SettingsSection: CaseIterable, Identifiable {
    case models
    case permissions
    case commands

    var id: Self { self }

    var title: String {
        switch self {
        case .models: "AI Models"
        case .permissions: "Permissions"
        case .commands: "Commands"
        }
    }

    var icon: String {
        switch self {
        case .models: "cpu"
        case .permissions: "lock.shield"
        case .commands: "command"
        }
    }
}

public struct SettingsView: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var selectedSection: SettingsSection = .models

    public init() {}

    public var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(selection: $selectedSection)
            Divider()
            VStack(spacing: 0) {
                contentHeader
                Divider()
                ScrollView {
                    sectionContent
                        .padding(.horizontal, 28)
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .frame(width: 659)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.92))
        }
        .frame(width: 900, height: 568)
        .background(settingsBackground)
        .preferredColorScheme(.dark)
    }

    private var contentHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedSection.title)
                    .font(.headline)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(height: 52)
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .models: ModelSettingsTab()
        case .permissions: PermissionsSettingsTab()
        case .commands: CommandLibraryView()
        }
    }

    @ViewBuilder
    private var settingsBackground: some View {
        if reduceTransparency {
            Color(nsColor: .windowBackgroundColor)
        } else {
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow)
        }
    }
}
