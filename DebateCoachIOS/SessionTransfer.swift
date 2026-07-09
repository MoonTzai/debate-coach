import Foundation

struct SessionTransferPayload: Codable {
    let exportedAt: String
    let messageCount: Int
    let messages: [SessionTransferMessage]
}

struct SessionTransferMessage: Codable {
    let role: String
    let content: String
}

enum SessionTransferError: LocalizedError {
    case invalidFile

    var errorDescription: String? {
        switch self {
        case .invalidFile:
            "Invalid file format. Please select a JSON file exported by this tool."
        }
    }
}

enum SessionTransfer {
    static func exportJSON(from session: ChatSession) throws -> Data {
        let payload = SessionTransferPayload(
            exportedAt: ISO8601DateFormatter().string(from: .now),
            messageCount: session.sortedMessages.count,
            messages: session.sortedMessages.map {
                SessionTransferMessage(role: $0.role.rawValue, content: $0.content)
            }
        )
        return try JSONEncoder.pretty.encode(payload)
    }

    static func exportMarkdown(from session: ChatSession) -> Data {
        var text = "# debate-coach Session Record\n\n"
        text += "Export time: \(DateFormatter.exportTimestamp.string(from: .now))\n\n---\n\n"
        for message in session.sortedMessages {
            let heading: String
            switch message.role {
            case .user: heading = "## You"
            case .assistant: heading = "## Debate Coach"
            case .system: heading = "### System"
            }
            text += "\(heading)\n\n\(message.content)\n\n---\n\n"
        }
        return Data(text.utf8)
    }

    static func importPayload(from data: Data) throws -> SessionTransferPayload {
        let decoder = JSONDecoder()
        let payload = try decoder.decode(SessionTransferPayload.self, from: data)
        guard !payload.messages.isEmpty else {
            throw SessionTransferError.invalidFile
        }
        return payload
    }

    static func makeFilename(for session: ChatSession, ext: String) -> String {
        let safeTitle = sanitize(session.title)
        return "debate-coach-session-\(safeTitle)-\(DateFormatter.filenameTimestamp.string(from: .now)).\(ext)"
    }

    static func suggestedTitle(from firstUserMessage: String?) -> String {
        guard let firstUserMessage, !firstUserMessage.isEmpty else {
            return "Imported Session"
        }
        let trimmed = firstUserMessage
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(28)).isEmpty ? "Imported Session" : String(trimmed.prefix(28))
    }

    private static func sanitize(_ text: String) -> String {
        let invalid = CharacterSet(charactersIn: "\\/:*?\"<>|,")
        let clean = text.components(separatedBy: invalid).joined(separator: "-")
        let compact = clean.replacingOccurrences(of: " ", with: "-")
        return compact.isEmpty ? "session" : compact
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension DateFormatter {
    static let exportTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static let filenameTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd.HHmm"
        return formatter
    }()
}
