import XCTest
@testable import OmniAct

final class CommandStorePersistenceTests: XCTestCase {
    func testFactoryCatalogLoadsFromAnEmptyTemporaryDirectory() throws {
        let directory = try makeTemporaryCommandDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = CommandStore(directory: directory)

        XCTAssertEqual(store.commands.count, 6)
        XCTAssertEqual(store.commands.map(\.id), FactoryCommandCatalog.commands.map(\.id))
        XCTAssertTrue(store.loadWarnings.isEmpty)
    }

    func testRelaunchReloadsFactoryOverrideAndCustomCommand() throws {
        let directory = try makeTemporaryCommandDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = CommandStore(directory: directory)
        var fix = try XCTUnwrap(store.command(withID: "factory.fix"))
        fix.title = "Repair prose"
        try store.update(fix)
        let custom = makeCustomCommand(token: "/release-notes")
        try store.create(custom)

        let reloaded = CommandStore(directory: directory)

        XCTAssertEqual(reloaded.command(withID: "factory.fix")?.title, "Repair prose")
        XCTAssertEqual(reloaded.command(withID: custom.id)?.command, "/release-notes")
    }

    func testCorruptFileDoesNotHideOtherValidCommandFiles() throws {
        let directory = try makeTemporaryCommandDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = CommandStore(directory: directory)
        let custom = makeCustomCommand(token: "/valid-command")
        try store.create(custom)
        try Data("{ broken".utf8).write(to: directory.appendingPathComponent("broken.json"))

        let reloaded = CommandStore(directory: directory)

        XCTAssertEqual(reloaded.command(withID: custom.id)?.command, "/valid-command")
        XCTAssertEqual(reloaded.loadWarnings.count, 1)
        XCTAssertTrue(reloaded.loadWarnings[0].contains("Repair or remove"))
    }

    func testPersistedCommandIsDeterministicPrettyJSONAndLeavesNoTemporaryFile() throws {
        let directory = try makeTemporaryCommandDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = CommandStore(directory: directory)
        let custom = makeCustomCommand(token: "/atomic-command")
        try store.create(custom)
        let file = store.fileURL(for: custom)
        let json = try String(contentsOf: file, encoding: .utf8)
        let decoded = try JSONDecoder().decode(SlashCommand.self, from: Data(json.utf8))
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)

        XCTAssertEqual(decoded.id, custom.id)
        XCTAssertTrue(json.contains("\n"))
        XCTAssertFalse(json.contains("apiKey"))
        XCTAssertFalse(json.contains("selectedText"))
        XCTAssertEqual(files.filter { $0.pathExtension == "json" }.count, 1)
        XCTAssertFalse(files.contains { $0.lastPathComponent.contains(".tmp") })
    }
}
