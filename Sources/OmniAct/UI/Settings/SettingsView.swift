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
        NavigationSplitView {
            SettingsSidebar(selection: $selectedSection)
                .navigationSplitViewColumnWidth(
                    min: SettingsDesignMetrics.sidebarMinimumWidth,
                    ideal: SettingsDesignMetrics.sidebarIdealWidth,
                    max: SettingsDesignMetrics.sidebarMaximumWidth
                )
                .toolbar(removing: .sidebarToggle)
        } detail: {
            sectionContent
                .frame(minWidth: SettingsDesignMetrics.detailMinimumWidth)
                .navigationTitle(selectedSection.title)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(
            minWidth: SettingsDesignMetrics.windowMinimumWidth,
            minHeight: SettingsDesignMetrics.windowMinimumHeight
        )
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .models:
            ModelSettingsTab()
        case .permissions:
            PermissionsSettingsTab()
        case .commands:
            CommandLibraryView()
        }
    }
}
