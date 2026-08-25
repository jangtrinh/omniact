import XCTest
@testable import OmniAct

@MainActor
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

    func testLoaderRejectsSymlinksAndNonRegularFilesWithoutHidingValidCommands() throws {
        let directory = try makeTemporaryCommandDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = CommandStore(directory: directory)
        let custom = makeCustomCommand(token: "/safe-command")
        try store.create(custom)

        let linkedFile = directory.appendingPathComponent("linked.json")
        try FileManager.default.createSymbolicLink(at: linkedFile, withDestinationURL: store.fileURL(for: custom))
        try FileManager.default.createDirectory(at: directory.appendingPathComponent("directory.json"), withIntermediateDirectories: true)

        let reloaded = CommandStore(directory: directory)

        XCTAssertEqual(reloaded.command(withID: custom.id)?.command, "/safe-command")
        XCTAssertEqual(reloaded.loadWarnings.count, 2)
        XCTAssertTrue(reloaded.loadWarnings.allSatisfy { $0.contains("Skipped an invalid command file") })
    }

    func testLoaderSkipsOversizedFilesAndKeepsOtherCommands() throws {
        let directory = try makeTemporaryCommandDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = CommandStore(directory: directory)
        let custom = makeCustomCommand(token: "/small-command")
        try store.create(custom)
        let oversizedFile = directory.appendingPathComponent("oversized.json")
        try Data(repeating: 0, count: CommandStorePersistence.maximumFileByteCount + 1).write(to: oversizedFile)

        let reloaded = CommandStore(directory: directory)

        XCTAssertEqual(reloaded.command(withID: custom.id)?.command, "/small-command")
        XCTAssertTrue(reloaded.loadWarnings.contains { $0.contains("maximum file size") })
    }

    func testLoaderCapsCommandFileCountDeterministically() throws {
        let directory = try makeTemporaryCommandDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        for index in 0...CommandStorePersistence.maximumFileCount {
            let command = SlashCommand(
                id: "bulk-command-\(index)",
                command: "/bulk-\(index)",
                title: "Bulk \(index)",
                description: "Boundary test",
                icon: "sparkles",
                systemPrompt: "System",
                promptTemplate: "{text}",
                origin: .custom,
                order: index
            )
            _ = try CommandStorePersistence.write(command, to: directory, fileManager: .default)
        }

        let reloaded = CommandStore(directory: directory)

        XCTAssertEqual(reloaded.commands.filter { $0.id.hasPrefix("bulk-command-") }.count, CommandStorePersistence.maximumFileCount)
        XCTAssertTrue(reloaded.loadWarnings.contains { $0.contains("maximum of \(CommandStorePersistence.maximumFileCount) files") })
        XCTAssertThrowsError(try reloaded.create(makeCustomCommand(token: "/over-the-limit")))
    }

    func testStoreRejectsOversizedStableIdentifiersBeforeWritingFiles() throws {
        let directory = try makeTemporaryCommandDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let id = String(repeating: "a", count: CommandStorePersistence.maximumStableIDByteCount + 1)
        let command = SlashCommand(
            id: id,
            command: "/long-id",
            title: "Long ID",
            description: "Boundary test",
            icon: "sparkles",
            systemPrompt: "System",
            promptTemplate: "{text}",
            origin: .custom,
            order: 99
        )
        let store = CommandStore(directory: directory)

        XCTAssertTrue(CommandValidator.validate([command]).contains(.identifierTooLong))
        XCTAssertThrowsError(try store.create(command))
        XCTAssertTrue((try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)).isEmpty)
    }

    func testStoreRejectsCommandsThatExceedThePersistedByteLimit() throws {
        let directory = try makeTemporaryCommandDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let command = SlashCommand(
            id: UUID().uuidString.lowercased(),
            command: "/large-command",
            title: "Large Command",
            description: "Boundary test",
            icon: "sparkles",
            systemPrompt: "System",
            promptTemplate: String(repeating: "x", count: CommandStorePersistence.maximumFileByteCount + 1),
            origin: .custom,
            order: 99
        )
        let store = CommandStore(directory: directory)

        XCTAssertThrowsError(try store.create(command))
        XCTAssertTrue((try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)).isEmpty)
    }

    func testWriterRejectsASymlinkDestinationWithoutFollowingIt() throws {
        let directory = try makeTemporaryCommandDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let command = makeCustomCommand(token: "/symlink-target")
        let destination = CommandStorePersistence.fileURL(forID: command.id, in: directory)
        let protectedFile = directory.appendingPathComponent("protected.json")
        try Data("protected".utf8).write(to: protectedFile)
        try FileManager.default.createSymbolicLink(at: destination, withDestinationURL: protectedFile)

        XCTAssertThrowsError(try CommandStorePersistence.write(command, to: directory, fileManager: .default))
        XCTAssertEqual(try String(contentsOf: protectedFile, encoding: .utf8), "protected")
    }

    func testDirectoryWarningIncludesTheActualDirectoryPath() throws {
        let directory = try makeTemporaryCommandDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("not-a-directory")
        try Data("not a directory".utf8).write(to: file)

        let store = CommandStore(directory: file)

        XCTAssertTrue(store.loadWarnings.contains { $0.contains(file.path) })
        XCTAssertFalse(store.loadWarnings.contains { $0.contains("(directory.path)") })
    }
}
