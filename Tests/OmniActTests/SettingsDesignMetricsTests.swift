import XCTest
@testable import OmniAct

final class SettingsDesignMetricsTests: XCTestCase {
    func testNativeSettingsWindowAndColumnGeometry() {
        XCTAssertEqual(SettingsDesignMetrics.windowWidth, 820)
        XCTAssertEqual(SettingsDesignMetrics.windowHeight, 540)
        XCTAssertEqual(SettingsDesignMetrics.windowMinimumWidth, 740)
        XCTAssertEqual(SettingsDesignMetrics.windowMinimumHeight, 520)
        XCTAssertEqual(SettingsDesignMetrics.sidebarMinimumWidth, 200)
        XCTAssertEqual(SettingsDesignMetrics.sidebarIdealWidth, 240)
        XCTAssertEqual(SettingsDesignMetrics.sidebarMaximumWidth, 280)
        XCTAssertEqual(SettingsDesignMetrics.detailMinimumWidth, 460)
    }

    func testNativeSettingsProportionsMatchSystemSettingsReference() {
        XCTAssertEqual(
            SettingsDesignMetrics.windowWidth - SettingsDesignMetrics.sidebarIdealWidth,
            580
        )
        XCTAssertGreaterThanOrEqual(
            SettingsDesignMetrics.windowMinimumWidth - SettingsDesignMetrics.sidebarMaximumWidth,
            SettingsDesignMetrics.detailMinimumWidth
        )
        XCTAssertLessThanOrEqual(
            SettingsDesignMetrics.sidebarIdealWidth / SettingsDesignMetrics.windowWidth,
            0.31
        )
        XCTAssertEqual(SettingsDesignMetrics.controlWidth, 240)
    }
}
