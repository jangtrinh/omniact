import Foundation
import XCTest

final class SettingsNativeShellSourceTests: XCTestCase {
    func testSidebarAndToolbarRemainSystemOwned() throws {
        let settingsView = try source(named: "SettingsView.swift")
        let settingsSidebar = try source(named: "SettingsSidebar.swift")
        let modelSettingsTab = try source(named: "ModelSettingsTab.swift")

        XCTAssertTrue(settingsSidebar.contains("List(selection: $selection)"))
        XCTAssertTrue(settingsSidebar.contains(".listStyle(.sidebar)"))
        XCTAssertTrue(settingsView.contains(".navigationTitle(selectedSection.title)"))
        XCTAssertTrue(settingsView.contains(".toolbar(removing: .sidebarToggle)"))
        XCTAssertTrue(modelSettingsTab.contains("safeAreaInset(edge: .bottom"))

        XCTAssertFalse(settingsSidebar.contains("ScrollView"))
        XCTAssertFalse(settingsSidebar.contains("Capsule"))
        XCTAssertFalse(settingsSidebar.contains("controlActiveState"))
        XCTAssertFalse(settingsSidebar.contains(".searchable("))
        XCTAssertFalse(settingsSidebar.contains("Section(\"OmniAct\")"))
        XCTAssertFalse(settingsSidebar.contains(".navigationTitle("))
        XCTAssertFalse(settingsView.contains("detailHeader"))
        XCTAssertFalse(settingsView.contains("ToolbarItem"))
        XCTAssertFalse(settingsView.contains("ControlGroup"))
        XCTAssertFalse(settingsView.contains("historyIndex"))
        XCTAssertFalse(settingsView.contains("searchText"))
        XCTAssertFalse(modelSettingsTab.contains("SettingsCallout"))
        XCTAssertFalse(modelSettingsTab.contains("result.contains"))
    }

    private func source(named fileName: String) throws -> String {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourceURL = repositoryRoot
            .appendingPathComponent("Sources/OmniAct/UI/Settings")
            .appendingPathComponent(fileName)
        return try String(contentsOf: sourceURL, encoding: .utf8)
    }
}
