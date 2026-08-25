import XCTest
@testable import OmniAct

private final class InMemoryAPIKeyStorage: APIKeyStorage, @unchecked Sendable {
    private var keys: [String: String] = [:]

    @discardableResult
    func save(key: String, account: String) -> Bool {
        keys[account] = key
        return true
    }

    func load(account: String) -> String? {
        keys[account]
    }
}

@MainActor
final class OmniActTests: XCTestCase {
    func testCommandRouterMatching() {
        let router = CommandRouter.shared

        let all = router.matchCommands(query: "")
        XCTAssertEqual(all.count, 6)

        let fixMatches = router.matchCommands(query: "/fix")
        XCTAssertTrue(fixMatches.contains { $0.command == "/fix" })

        let translateMatches = router.matchCommands(query: "translate")
        XCTAssertTrue(translateMatches.contains { $0.command == "/translate" })
    }

    func testPromptBuilding() {
        let router = CommandRouter.shared
        let fixCmd = router.builtInCommands.first { $0.command == "/fix" }

        let (sys, user) = router.buildPrompt(
            command: fixCmd,
            rawInput: "/fix",
            selectedText: "Thiss has a typo."
        )

        XCTAssertTrue(sys.contains("editor"))
        XCTAssertTrue(user.contains("Thiss has a typo."))
    }

    func testPromptBuildingWithTypedArg() {
        let router = CommandRouter.shared
        let fixCmd = router.builtInCommands.first { $0.command == "/fix" }

        let (sys, user) = router.buildPrompt(
            command: fixCmd,
            rawInput: "/fix I has an typo here",
            selectedText: ""
        )

        XCTAssertTrue(sys.contains("editor"))
        XCTAssertTrue(user.contains("I has an typo here"))
    }

    func testAppConfigPersistence() {
        let suiteName = "OmniActTests.AppConfigPersistence.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let keyStorage = InMemoryAPIKeyStorage()
        let config = AppConfig(userDefaults: defaults, keyStorage: keyStorage)
        config.saveConfiguration(
            provider: .groq,
            baseURL: "https://api.groq.com/openai/v1",
            modelName: "openai/gpt-oss-20b",
            apiKey: "gsk_test123"
        )

        let active = config.getActiveConfiguration()
        XCTAssertEqual(active.providerType, .groq)
        XCTAssertEqual(active.model, "openai/gpt-oss-20b")
        XCTAssertEqual(active.baseURL, "https://api.groq.com/openai/v1")
        XCTAssertEqual(active.apiKey, "gsk_test123")
    }

    func testNaturalLanguageCommandResolution() {
        let router = CommandRouter.shared

        let (fix1, _) = router.resolveCommand(from: "fix")
        XCTAssertEqual(fix1?.command, "/fix")

        let (fix2, _) = router.resolveCommand(from: "fix please check grammar")
        XCTAssertEqual(fix2?.command, "/fix")

        let (translate1, _) = router.resolveCommand(from: "translate vi")
        XCTAssertEqual(translate1?.command, "/translate")

        let (summarize1, _) = router.resolveCommand(from: "summarize")
        XCTAssertEqual(summarize1?.command, "/summarize")
    }

    func testLLMProviderDefaults() {
        let groq = LLMConfiguration(providerType: .groq)
        XCTAssertEqual(groq.baseURL, "https://api.groq.com/openai/v1")
        XCTAssertEqual(groq.model, "llama-3.3-70b-versatile")

        let ollama = LLMConfiguration(providerType: .ollama)
        XCTAssertEqual(ollama.baseURL, "http://localhost:11434/v1")
        XCTAssertEqual(ollama.model, "llama3.2:3b")
    }
}
