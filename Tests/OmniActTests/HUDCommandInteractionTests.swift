import XCTest
@testable import OmniAct

@MainActor
final class HUDCommandInteractionTests: XCTestCase {
    func testQuickActionsUseLiveEnabledCommandsByStableIdentifier() throws {
        let directory = try makeTemporaryCommandDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = CommandStore(directory: directory)
        var fix = try XCTUnwrap(store.command(withID: "factory.fix"))
        fix.command = "/polish"
        fix.title = "Polish Writing"
        try store.update(fix)
        let viewModel = HUDViewModel(commandStore: store)

        let action = try XCTUnwrap(viewModel.quickActions.first { $0.commandID == fix.id })
        XCTAssertEqual(action.title, "Polish Writing")
        XCTAssertEqual(viewModel.quickActionInput(for: action), "/polish")
        XCTAssertTrue(viewModel.prepareQuickAction(action))
        XCTAssertEqual(viewModel.selectedCommand?.id, fix.id)
        XCTAssertEqual(viewModel.inputText, "/polish")

        try store.setEnabled(false, for: fix.id)

        XCTAssertFalse(viewModel.quickActions.contains { $0.commandID == fix.id })
        XCTAssertNil(viewModel.quickActionInput(for: action))
        XCTAssertFalse(viewModel.prepareQuickAction(action))
    }

    func testStaleSelectedCommandDoesNotFallBackToFreeformAfterDisable() throws {
        let directory = try makeTemporaryCommandDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = CommandStore(directory: directory)
        let viewModel = HUDViewModel(commandStore: store)
        let fix = try XCTUnwrap(store.command(withID: "factory.fix"))

        viewModel.selectedCommand = fix
        viewModel.inputText = "/fix selected text"
        try store.setEnabled(false, for: fix.id)
        viewModel.execute()

        XCTAssertNil(viewModel.selectedCommand)
        XCTAssertFalse(viewModel.isStreaming)
        XCTAssertEqual(viewModel.errorMessage, "That command is no longer enabled. Choose another command.")
    }

    func testSavedCustomCommandIsKeyboardNavigableAndSelectableWithoutRelaunch() throws {
        let directory = try makeTemporaryCommandDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = CommandStore(directory: directory)
        let viewModel = HUDViewModel(commandStore: store)
        viewModel.inputText = "/release"

        let first = makeCustomCommand(token: "/release-notes", aliases: ["release notes"])
        let second = makeCustomCommand(token: "/release-digest", aliases: ["release digest"])
        try store.create(first)
        try store.create(second)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        XCTAssertEqual(viewModel.matchedCommands.map(\.id), [first.id, second.id])
        XCTAssertEqual(viewModel.autocompleteSelectionIndex, 0)
        viewModel.moveAutocompleteSelection(.down)
        XCTAssertEqual(viewModel.autocompleteSelectionIndex, 1)
        viewModel.moveAutocompleteSelection(.up)
        XCTAssertEqual(viewModel.autocompleteSelectionIndex, 0)
        XCTAssertTrue(viewModel.prepareAutocompleteSelection())
        XCTAssertEqual(viewModel.selectedCommand?.id, first.id)
        XCTAssertEqual(viewModel.inputText, "/release-notes ")
    }

    func testOverflowingAutocompleteUsesBoundedRowsAndStableSelectionTarget() {
        let commands = (0..<(HUDAutocompleteViewport.visibleRowBudget + 2)).map { index in
            makeCustomCommand(token: "/overflow-\(index)", aliases: ["overflow-\(index)"])
        }
        var selectedIndex: Int? = 0
        for _ in 1..<commands.count {
            selectedIndex = HUDAutocompleteSelection.movedIndex(
                from: selectedIndex,
                commandCount: commands.count,
                direction: .down
            )
        }

        XCTAssertEqual(
            HUDAutocompleteViewport.visibleRowCount(for: commands.count),
            HUDAutocompleteViewport.visibleRowBudget
        )
        XCTAssertEqual(
            HUDAutocompleteViewport.selectedStableID(commands: commands, selectedIndex: selectedIndex),
            commands.last?.id
        )
    }
}
