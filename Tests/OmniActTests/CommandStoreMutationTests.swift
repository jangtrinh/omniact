import XCTest
@testable import OmniAct

final class CommandStoreMutationTests: XCTestCase {
    func testCreateUpdateDuplicateEnableReorderAndDeleteCustomCommand() throws {
        let directory = try makeTemporaryCommandDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = CommandStore(directory: directory)
        let custom = makeCustomCommand(token: "/project-update")
        try store.create(custom)
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.fileURL(for: custom).path))

        var edited = try XCTUnwrap(store.command(withID: custom.id))
        edited.title = "Project Update"
        try store.update(edited)
        let duplicate = try store.duplicate(id: custom.id)
        try store.setEnabled(false, for: duplicate.id)
        try store.move(id: duplicate.id, by: -1)

        XCTAssertEqual(store.command(withID: custom.id)?.title, "Project Update")
        XCTAssertFalse(store.command(withID: duplicate.id)?.enabled ?? true)
        XCTAssertLessThan(store.command(withID: duplicate.id)?.order ?? .max, store.command(withID: custom.id)?.order ?? .min)

        try store.deleteCustom(id: custom.id)
        XCTAssertNil(store.command(withID: custom.id))
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.fileURL(for: custom).path))
    }

    func testResetFactoryRestoresShippedDefinitionAndRemovesOverride() throws {
        let directory = try makeTemporaryCommandDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = CommandStore(directory: directory)
        var fix = try XCTUnwrap(store.command(withID: "factory.fix"))
        fix.systemPrompt = "Changed prompt"
        try store.update(fix)
        XCTAssertTrue(store.isFactoryModified(fix))

        try store.resetFactory(id: fix.id)
        let reset = try XCTUnwrap(store.command(withID: fix.id))

        XCTAssertEqual(reset, FactoryCommandCatalog.command(withID: fix.id))
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.fileURL(for: fix).path))
    }

    func testResetAllFactoryCommandsKeepsCustomCommands() throws {
        let directory = try makeTemporaryCommandDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = CommandStore(directory: directory)
        var tone = try XCTUnwrap(store.command(withID: "factory.tone"))
        tone.enabled = false
        try store.update(tone)
        let custom = makeCustomCommand(token: "/keep-me")
        try store.create(custom)

        try store.resetAllFactoryCommands()

        XCTAssertEqual(store.command(withID: tone.id), FactoryCommandCatalog.command(withID: tone.id))
        XCTAssertEqual(store.command(withID: custom.id)?.command, "/keep-me")
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.fileURL(for: custom).path))
    }
}
