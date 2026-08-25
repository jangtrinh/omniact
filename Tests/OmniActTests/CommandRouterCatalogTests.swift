import XCTest
@testable import OmniAct

final class CommandRouterCatalogTests: XCTestCase {
    func testExactCaseInsensitiveTokensAndDataAliasesResolveSafely() {
        let catalog = MutableCommandCatalog(FactoryCommandCatalog.commands)
        let router = CommandRouter(catalog: catalog)

        XCTAssertEqual(router.resolveCommand(from: "/FiX correct this").0?.id, "factory.fix")
        XCTAssertEqual(router.resolveCommand(from: "GRAMMAR correct this").0?.id, "factory.fix")
        XCTAssertEqual(router.resolveCommand(from: "rewrite formal").0?.id, "factory.tone")
        XCTAssertNil(router.resolveCommand(from: "/fixx should not match").0)
        XCTAssertEqual(router.resolveCommand(from: "/fixx should not match").1, "/fixx should not match")
    }

    func testDisabledCommandsNeverMatchAppearOrExecuteAsCommands() {
        var disabledFix = FactoryCommandCatalog.commands[0]
        disabledFix.enabled = false
        let catalog = MutableCommandCatalog([disabledFix])
        let router = CommandRouter(catalog: catalog)

        XCTAssertTrue(router.matchCommands(query: "fix").isEmpty)
        XCTAssertNil(router.resolveCommand(from: "/fix text").0)
        let prompt = router.buildPrompt(command: disabledFix, rawInput: "/fix text", selectedText: "selected")
        XCTAssertNotEqual(prompt.systemPrompt, disabledFix.systemPrompt)
    }

    func testPromptInterpolationPreservesTextAndArgumentBehavior() {
        let command = makeCustomCommand(
            token: "/interpolate",
            aliases: ["interpolate"],
            promptTemplate: "text={text}; arg={arg}"
        )
        let router = CommandRouter(catalog: MutableCommandCatalog([command]))

        let selected = router.buildPrompt(command: nil, rawInput: "/interpolate concise", selectedText: "Selected text")
        let typed = router.buildPrompt(command: nil, rawInput: "/interpolate typed text", selectedText: "")
        let empty = router.buildPrompt(command: nil, rawInput: "/interpolate", selectedText: "")

        XCTAssertEqual(selected.userPrompt, "text=Selected text; arg=concise")
        XCTAssertEqual(typed.userPrompt, "text=typed text; arg=typed text")
        XCTAssertEqual(empty.userPrompt, "text=; arg=default")
    }
}
