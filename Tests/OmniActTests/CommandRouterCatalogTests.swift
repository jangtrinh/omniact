import XCTest
@testable import OmniAct

@MainActor
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
            systemPrompt: "system text={text}; arg={arg}",
            promptTemplate: "text={text}; arg={arg}"
        )
        let router = CommandRouter(catalog: MutableCommandCatalog([command]))

        let selected = router.buildPrompt(command: nil, rawInput: "/interpolate concise", selectedText: "Selected text")
        let typed = router.buildPrompt(command: nil, rawInput: "/interpolate typed text", selectedText: "")
        let empty = router.buildPrompt(command: nil, rawInput: "/interpolate", selectedText: "")

        XCTAssertEqual(selected.userPrompt, "text=Selected text; arg=concise")
        XCTAssertEqual(selected.systemPrompt, "system text=Selected text; arg=concise")
        XCTAssertEqual(typed.userPrompt, "text=typed text; arg=typed text")
        XCTAssertEqual(typed.systemPrompt, "system text=typed text; arg=typed text")
        XCTAssertEqual(empty.userPrompt, "text=; arg=default")
        XCTAssertEqual(empty.systemPrompt, "system text=; arg=default")
    }

    func testInterpolationPreservesLiteralTokensInSelectedTextForBothPrompts() {
        let command = interpolationCommand()
        let router = CommandRouter(catalog: MutableCommandCatalog([command]))
        let selectedText = "keep literal {text} and {arg}"

        let prompt = router.buildPrompt(
            command: nil,
            rawInput: "/interpolate concise",
            selectedText: selectedText
        )

        XCTAssertEqual(prompt.systemPrompt, "system text=\(selectedText); arg=concise")
        XCTAssertEqual(prompt.userPrompt, "text=\(selectedText); arg=concise")
    }

    func testInterpolationPreservesLiteralTokensInArgumentForBothPrompts() {
        let command = interpolationCommand()
        let router = CommandRouter(catalog: MutableCommandCatalog([command]))
        let argument = "keep literal {text} and {arg}"

        let prompt = router.buildPrompt(
            command: nil,
            rawInput: "/interpolate \(argument)",
            selectedText: ""
        )

        XCTAssertEqual(prompt.systemPrompt, "system text=\(argument); arg=\(argument)")
        XCTAssertEqual(prompt.userPrompt, "text=\(argument); arg=\(argument)")
    }

    private func interpolationCommand() -> SlashCommand {
        makeCustomCommand(
            token: "/interpolate",
            aliases: ["interpolate"],
            systemPrompt: "system text={text}; arg={arg}",
            promptTemplate: "text={text}; arg={arg}"
        )
    }
}
