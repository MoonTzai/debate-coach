import Foundation
import Security

final class AppSettingsStore: ObservableObject {
    private enum DefaultsKey {
        static let baseURL = "debateCoach.baseURL"
        static let model = "debateCoach.model"
        static let language = "debateCoach.language"
        static let riskAccepted = "debateCoach.riskAccepted"
        static let currentSessionID = "debateCoach.currentSessionID"
    }

    private let defaults: UserDefaults
    private let keychain = KeychainService()
    private let keychainAccount = "debate-coach.api-key"

    @Published var baseURL: String { didSet { save(baseURL, for: DefaultsKey.baseURL) } }
    @Published var model: String { didSet { save(model, for: DefaultsKey.model) } }
    @Published var language: AppLanguage { didSet { save(language.rawValue, for: DefaultsKey.language) } }
    @Published var riskAccepted: Bool { didSet { defaults.set(riskAccepted, forKey: DefaultsKey.riskAccepted) } }
    @Published var currentSessionID: String { didSet { save(currentSessionID, for: DefaultsKey.currentSessionID) } }
    @Published var apiKey: String

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.baseURL = defaults.string(forKey: DefaultsKey.baseURL) ?? "https://api.deepseek.com/v1/chat/completions"
        self.model = defaults.string(forKey: DefaultsKey.model) ?? "deepseek-v4-pro"
        self.language = AppLanguage(rawValue: defaults.string(forKey: DefaultsKey.language) ?? "") ?? .zh
        self.riskAccepted = defaults.bool(forKey: DefaultsKey.riskAccepted)
        self.currentSessionID = defaults.string(forKey: DefaultsKey.currentSessionID) ?? ""
        self.apiKey = keychain.read(account: keychainAccount) ?? ""
    }

    var hasAPIKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var providerConfig: ProviderConfig {
        ProviderConfig(
            baseURL: baseURL.trimmingCharacters(in: .whitespacesAndNewlines),
            model: model.trimmingCharacters(in: .whitespacesAndNewlines),
            apiKeyKeychainRef: keychainAccount,
            language: language,
            riskAccepted: riskAccepted
        )
    }

    func saveAPIKey(_ value: String) {
        apiKey = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if apiKey.isEmpty {
            keychain.delete(account: keychainAccount)
        } else {
            keychain.save(apiKey, account: keychainAccount)
        }
    }

    func clearAPIKey() {
        apiKey = ""
        keychain.delete(account: keychainAccount)
    }

    private func save(_ value: String, for key: String) {
        defaults.set(value, forKey: key)
    }
}

private final class KeychainService {
    private let service = "com.example.DebateCoachIOS"

    func save(_ value: String, account: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data
        SecItemAdd(attributes as CFDictionary, nil)
    }

    func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return value
    }

    func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
