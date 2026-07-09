import Foundation
import SwiftData
import SwiftUI

enum ChatRole: String, Codable, CaseIterable {
    case user
    case assistant
    case system
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case zh
    case en

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .zh: "中文"
        case .en: "English"
        }
    }
}

struct ProviderConfig: Equatable {
    var baseURL: String
    var model: String
    var apiKeyKeychainRef: String
    var language: AppLanguage
    var riskAccepted: Bool
}

@Model
final class ChatSession {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.session) var messages: [ChatMessage]

    init(
        id: UUID = UUID(),
        title: String = "New Conversation",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        deletedAt: Date? = nil,
        messages: [ChatMessage] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.messages = messages
    }

    var sortedMessages: [ChatMessage] {
        messages.sorted { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.id.uuidString < rhs.id.uuidString
            }
            return lhs.createdAt < rhs.createdAt
        }
    }

    var latestPreview: String {
        sortedMessages.last?.content ?? ""
    }

    var hasContent: Bool {
        sortedMessages.contains { message in
            !message.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var isDeleted: Bool {
        deletedAt != nil
    }

    var recycleExpiryDate: Date? {
        deletedAt?.addingTimeInterval(7 * 24 * 60 * 60)
    }
}

@Model
final class ChatMessage {
    @Attribute(.unique) var id: UUID
    var roleRawValue: String
    var content: String
    var createdAt: Date
    var session: ChatSession?

    init(
        id: UUID = UUID(),
        role: ChatRole,
        content: String,
        createdAt: Date = .now,
        session: ChatSession? = nil
    ) {
        self.id = id
        self.roleRawValue = role.rawValue
        self.content = content
        self.createdAt = createdAt
        self.session = session
    }

    var role: ChatRole {
        get { ChatRole(rawValue: roleRawValue) ?? .user }
        set { roleRawValue = newValue.rawValue }
    }
}
