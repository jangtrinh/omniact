import Foundation

public protocol APIKeyStorage: Sendable {
    @discardableResult
    func save(key: String, account: String) -> Bool
    func load(account: String) -> String?
}

private struct KeychainAPIKeyStorage: APIKeyStorage {
    @discardableResult
    func save(key: String, account: String) -> Bool {
        KeychainHelper.shared.save(key: key, account: account)
    }

    func load(account: String) -> String? {
        KeychainHelper.shared.load(account: account)
    }
}

private final class TransientAPIKeyStorage: APIKeyStorage, @unchecked Sendable {
    private let lock = NSLock()
    private var keys: [String: String] = [:]

    @discardableResult
    func save(key: String, account: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        keys[account] = key
        return true
    }

    func load(account: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return keys[account]
    }
}

public final class AppConfig: @unchecked Sendable {
    public static let shared = AppConfig()

    private let userDefaults: UserDefaults
    private let keyStorage: any APIKeyStorage
    private let activeProviderKey = "OmniAct_ActiveProvider"

    private init() {
        if ProcessInfo.processInfo.environment["OMNIACT_UI_SMOKE_TEST"] == "1" {
            let suite = "OmniAct.UISmoke.\(ProcessInfo.processInfo.processIdentifier)"
            guard let smokeDefaults = UserDefaults(suiteName: suite) else {
                preconditionFailure("Could not create isolated UI smoke-test defaults")
            }
            userDefaults = smokeDefaults
            keyStorage = TransientAPIKeyStorage()
        } else {
            userDefaults = .standard
            keyStorage = KeychainAPIKeyStorage()
        }
    }

    public init(userDefaults: UserDefaults, keyStorage: any APIKeyStorage) {
        self.userDefaults = userDefaults
        self.keyStorage = keyStorage
    }

    public var activeProvider: LLMProviderType {
        get {
            if let raw = userDefaults.string(forKey: activeProviderKey),
               let type = LLMProviderType(rawValue: raw) {
                return type
            }
            return .groq
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: activeProviderKey)
        }
    }

    public func getBaseURL(for type: LLMProviderType) -> String {
        return userDefaults.string(forKey: "OmniAct_BaseURL_\(type.rawValue)") ?? type.defaultBaseURL
    }

    public func setBaseURL(_ url: String, for type: LLMProviderType) {
        userDefaults.set(url, forKey: "OmniAct_BaseURL_\(type.rawValue)")
    }

    public func getModelName(for type: LLMProviderType) -> String {
        return userDefaults.string(forKey: "OmniAct_ModelName_\(type.rawValue)") ?? type.defaultModel
    }

    public func setModelName(_ name: String, for type: LLMProviderType) {
        userDefaults.set(name, forKey: "OmniAct_ModelName_\(type.rawValue)")
    }

    public func getAPIKey(for type: LLMProviderType) -> String? {
        return keyStorage.load(account: type.rawValue)
    }

    public func setAPIKey(_ key: String, for type: LLMProviderType) {
        keyStorage.save(key: key, account: type.rawValue)
    }

    public func getActiveConfiguration() -> LLMConfiguration {
        let provider = activeProvider
        let baseURL = getBaseURL(for: provider)
        let model = getModelName(for: provider)
        let key = getAPIKey(for: provider)

        return LLMConfiguration(
            providerType: provider,
            baseURL: baseURL,
            model: model,
            apiKey: key,
            temperature: 0.3
        )
    }

    public func saveConfiguration(
        provider: LLMProviderType,
        baseURL: String,
        modelName: String,
        apiKey: String?
    ) {
        self.activeProvider = provider
        self.setBaseURL(baseURL, for: provider)
        self.setModelName(modelName, for: provider)
        if let key = apiKey, !key.isEmpty {
            self.setAPIKey(key, for: provider)
        }
    }
}
