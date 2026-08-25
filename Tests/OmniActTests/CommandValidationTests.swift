import XCTest
@testable import OmniAct

final class CommandValidationTests: XCTestCase {
    func testValidatorSurfacesEveryRequiredValidationError() {
        let factory = FactoryCommandCatalog.commands[0]
        let invalid = SlashCommand(
            id: factory.id,
            command: "/bad--token",
            aliases: ["", "grammar"],
            title: "",
            description: "",
            icon: "sparkles",
            systemPrompt: "",
            promptTemplate: "Use {unsupported}",
            origin: .custom,
            order: 10
        )
        var duplicateToken = makeCustomCommand(token: "/FIX")
        duplicateToken.aliases = ["another alias"]
        var emptyTemplate = makeCustomCommand(token: "/empty-template")
        emptyTemplate.promptTemplate = ""
        let blankID = SlashCommand(
            id: "",
            command: "/blank-id",
            title: "Blank ID",
            description: "",
            icon: "sparkles",
            systemPrompt: "Prompt",
            promptTemplate: "{text}",
            origin: .custom,
            order: 11
        )

        let issues = CommandValidator.validate([factory, invalid, duplicateToken, emptyTemplate, blankID])

        XCTAssertTrue(issues.contains(.emptyIdentifier))
        XCTAssertTrue(issues.contains(.duplicateIdentifier))
        XCTAssertTrue(issues.contains(.invalidSlashToken))
        XCTAssertTrue(issues.contains(.emptyTitle))
        XCTAssertTrue(issues.contains(.emptySystemPrompt))
        XCTAssertTrue(issues.contains(.emptyPromptTemplate))
        XCTAssertTrue(issues.contains(.emptyAlias))
        XCTAssertTrue(issues.contains(.duplicateSlashToken))
        XCTAssertTrue(issues.contains(.aliasCollision))
        XCTAssertTrue(issues.contains(.unsupportedPlaceholder))
    }

    func testStoreRejectsInvalidCustomCommandWithoutWritingIt() throws {
        let directory = try makeTemporaryCommandDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = CommandStore(directory: directory)
        let invalid = makeCustomCommand(token: "/UPPERCASE")

        XCTAssertThrowsError(try store.create(invalid)) { error in
            guard case CommandStoreError.validation(let issues) = error else {
                return XCTFail("Expected a validation error")
            }
            XCTAssertTrue(issues.contains(.invalidSlashToken))
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.fileURL(for: invalid).path))
    }

    func testValidSlashTokensAcceptLowercaseNumbersAndHyphens() {
        XCTAssertTrue(CommandValidator.isValidSlashToken("/fix-2"))
        XCTAssertFalse(CommandValidator.isValidSlashToken("fix"))
        XCTAssertFalse(CommandValidator.isValidSlashToken("/Fix"))
        XCTAssertFalse(CommandValidator.isValidSlashToken("/fix_2"))
    }
}
