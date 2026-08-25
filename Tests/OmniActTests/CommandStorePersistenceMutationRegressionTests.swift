import XCTest
@testable import OmniAct

@MainActor
final class CommandStorePersistenceMutationRegressionTests: XCTestCase {
    private let fullDirectoryMessage = "The command library already contains the maximum of 64 command files. Repair or remove a command file before adding another."

    func testUnrelatedCustomCreateKeepsMalformedFactoryOverrideForRepair() throws {
        let directory = try makeTemporaryCommandDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = CommandStore(directory: directory)
        let factoryFix = try XCTUnwrap(store.command(withID: "factory.fix"))
        let malformedFile = store.fileURL(for: factoryFix)
        let malformedData = Data("{ not valid JSON".utf8)
        try malformedData.write(to: malformedFile)
        store.reload()

        let custom = try store.create(makeCustomCommand(token: "/unrelated-save"))
        var updatedCustom = try XCTUnwrap(store.command(withID: custom.id))
        updatedCustom.title = "Updated unrelated save"
        try store.update(updatedCustom)

        XCTAssertTrue(FileManager.default.fileExists(atPath: malformedFile.path))
        XCTAssertEqual(try Data(contentsOf: malformedFile), malformedData)
    }

    func testCreateRejectsNewCandidateWhenMalformedFileUsesFinalSlot() throws {
        let directory = try makeTemporaryCommandDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let malformedFile = directory.appendingPathComponent("00-malformed.json")
        try Data("{ not valid JSON".utf8).write(to: malformedFile)
        let persisted = (0..<(CommandStorePersistence.maximumFileCount - 1)).map(persistedCommand)
        for command in persisted {
            _ = try CommandStorePersistence.write(command, to: directory, fileManager: .default)
        }

        let store = CommandStore(directory: directory)
        let attempted = makeCustomCommand(token: "/candidate-64", aliases: ["candidate 64"])

        XCTAssertEqual(store.commands.filter { $0.origin == .custom }.count, persisted.count)
        XCTAssertThrowsError(try store.create(attempted)) { error in
            XCTAssertEqual(error.localizedDescription, self.fullDirectoryMessage)
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.fileURL(for: attempted).path))

        let relaunched = CommandStore(directory: directory)
        XCTAssertEqual(
            Set(relaunched.commands.filter { $0.origin == .custom }.map(\.id)),
            Set(persisted.map(\.id))
        )
        XCTAssertNil(relaunched.command(withID: attempted.id))
    }

    private func persistedCommand(_ index: Int) -> SlashCommand {
        SlashCommand(
            id: "boundary-command-\(index)",
            command: "/boundary-\(index)",
            aliases: ["boundary-\(index)"],
            title: "Boundary \(index)",
            description: "Persistence boundary regression",
            icon: "sparkles",
            systemPrompt: "System",
            promptTemplate: "{text}",
            origin: .custom,
            order: index
        )
    }
}
