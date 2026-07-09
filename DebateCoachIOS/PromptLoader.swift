import Foundation

enum PromptLoaderError: LocalizedError {
    case missingResource(String)
    case unreadableResource(String)

    var errorDescription: String? {
        switch self {
        case let .missingResource(name):
            "Missing bundled prompt resource: \(name)"
        case let .unreadableResource(name):
            "Failed to read bundled prompt resource: \(name)"
        }
    }
}

enum PromptLoader {
    static func load(language: AppLanguage) throws -> String {
        let resourceName = language == .zh ? "SKILL" : "SKILL-EN"
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "md") else {
            throw PromptLoaderError.missingResource(resourceName)
        }
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw PromptLoaderError.unreadableResource(resourceName)
        }
    }

    static func loadPrivacyPolicy() -> String {
        guard let url = Bundle.main.url(forResource: "PrivacyPolicy", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "Privacy policy is unavailable in this build."
        }
        return text
    }
}
