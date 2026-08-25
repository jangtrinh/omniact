import XCTest
@testable import OmniAct

@MainActor
final class CommandLibraryViewModelTests: XCTestCase {
    func testCustomCommandStatusReflectsPersistenceInsteadOfEditorState() throws {
        let directory = try makeTemporaryCommandDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = CommandStore(directory: directory)
        let model = CommandLibraryViewModel(store: store)
        let saved = makeCustomCommand(token: "/saved-command")
        try store.create(saved)
        let persisted = try XCTUnwrap(store.command(withID: saved.id))

        model.beginEdit(persisted)
        XCTAssertEqual(model.originState(for: persisted), "Custom • saved")

        model.beginCreate()
        let draft = try XCTUnwrap(model.draft)
        XCTAssertEqual(model.originState(for: draft), "Custom • unsaved")
        XCTAssertEqual(model.originState(for: persisted), "Custom • saved")
    }
}
