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
    @State private var selectedSection: SettingsSection = .models

    public init() {}

    public var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(selection: $selectedSection)
            VStack(spacing: 0) {
                SettingsToolbar(title: selectedSection.title)
                sectionContent
            }
            .frame(
                width: SettingsDesignMetrics.contentWidth,
                height: SettingsDesignMetrics.windowHeight
            )
            .background(SettingsPalette.content)
        }
        .frame(
            width: SettingsDesignMetrics.windowWidth,
            height: SettingsDesignMetrics.windowHeight
        )
        .background(SettingsPalette.content)
        .background(SettingsWindowConfigurator(sectionTitle: selectedSection.title))
        .ignoresSafeArea(.container, edges: .top)
        .frame(
            width: SettingsDesignMetrics.windowWidth,
            height: SettingsDesignMetrics.contentLayoutHeight
        )
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .models:
            ModelSettingsTab()
        case .permissions:
            settingsScroll { PermissionsSettingsTab() }
        case .commands:
            settingsScroll { CommandLibraryView() }
        }
    }

    private func settingsScroll<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            content()
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(
            width: SettingsDesignMetrics.contentWidth,
            height: SettingsDesignMetrics.contentHeight
        )
    }
}
