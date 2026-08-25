import XCTest
@testable import OmniAct

final class SettingsDesignMetricsTests: XCTestCase {
    func testFigmaWindowAndPaneGeometry() {
        XCTAssertEqual(SettingsDesignMetrics.windowWidth, 900)
        XCTAssertEqual(SettingsDesignMetrics.windowHeight, 600)
        XCTAssertEqual(SettingsDesignMetrics.nativeTitlebarHeight, 32)
        XCTAssertEqual(SettingsDesignMetrics.contentLayoutHeight, 568)
        XCTAssertEqual(SettingsDesignMetrics.sidebarWidth, 240)
        XCTAssertEqual(SettingsDesignMetrics.contentWidth, 660)
        XCTAssertEqual(SettingsDesignMetrics.toolbarHeight, 52)
        XCTAssertEqual(SettingsDesignMetrics.contentHeight, 548)
    }

    func testFigmaSidebarAndFormGeometry() {
        XCTAssertEqual(SettingsDesignMetrics.navigationRowWidth, 212)
        XCTAssertEqual(SettingsDesignMetrics.navigationRowHeight, 30)
        XCTAssertEqual(SettingsDesignMetrics.formWidth, 604)
        XCTAssertEqual(SettingsDesignMetrics.formHeight, 300)
        XCTAssertEqual(SettingsDesignMetrics.controlHeight, 28)
        XCTAssertEqual(SettingsDesignMetrics.actionHeight, 30)
    }
}
