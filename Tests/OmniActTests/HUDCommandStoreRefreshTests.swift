import XCTest
@testable import OmniAct

final class HUDCommandStoreRefreshTests: XCTestCase {
    @MainActor
    func testSavingCommandRefreshesCurrentHUDAutocompleteWithoutRelaunch() throws {
        let directory = try makeTemporaryCommandDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = CommandStore(directory: directory)
        let viewModel = HUDViewModel(commandStore: store)
        viewModel.inputText = "/release"
        XCTAssertFalse(viewModel.matchedCommands.contains { $0.command == "/release-notes" })

        try store.create(makeCustomCommand(token: "/release-notes"))
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        XCTAssertTrue(viewModel.matchedCommands.contains { $0.command == "/release-notes" })
    }
}
