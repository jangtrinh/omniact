import XCTest
@testable import OmniAct

final class ModelSettingsStatusTests: XCTestCase {
    func testStatusPresentationKeepsProgressAndMeaningExplicit() {
        XCTAssertEqual(
            ModelSettingsStatus.idle.presentation,
            ModelSettingsStatusPresentation(
                message: "Test this provider before saving.",
                symbol: "bolt.horizontal.circle",
                tone: .secondary,
                showsProgress: false
            )
        )
        XCTAssertEqual(
            ModelSettingsStatus.testing(providerName: "Groq").presentation,
            ModelSettingsStatusPresentation(
                message: "Testing Groq…",
                symbol: nil,
                tone: .secondary,
                showsProgress: true
            )
        )
        XCTAssertEqual(ModelSettingsStatus.connected.presentation.tone, .success)
        XCTAssertEqual(ModelSettingsStatus.failed(message: "Timed out").presentation.tone, .warning)
        XCTAssertEqual(ModelSettingsStatus.saved.presentation.message, "Changes saved")
    }
}
