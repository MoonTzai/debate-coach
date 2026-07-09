import Foundation
import Network

struct LLMChatMessage: Codable, Hashable {
    let role: String
    let content: String
}

enum LLMRequestBuilder {
    static func buildBody(
        prompt: String,
        conversation: [LLMChatMessage],
        model: String
    ) throws -> Data {
        let request = ChatCompletionRequest(
            model: model.isEmpty ? "deepseek-v4-pro" : model,
            messages: [LLMChatMessage(role: "system", content: prompt)] + conversation,
            temperature: 0.7,
            maxTokens: 4096,
            stream: true
        )
        return try JSONEncoder().encode(request)
    }
}

actor ChatAPIClient {
    static let shared = ChatAPIClient()

    private var localNetworkWarmupHosts: Set<String> = []
    private var networkWarmupHosts: Set<String> = []

    func prepareConnectionIfNeeded(config: ProviderConfig) async {
        guard let url = URL(string: config.baseURL) else { return }

        do {
            try await warmUpLocalNetworkPermissionIfNeeded(for: url)
            try await warmUpGeneralNetworkPermissionIfNeeded(for: url)
        } catch {
            // Permission/network warmup is best-effort. We intentionally do not
            // surface failures here because the real send path will handle them.
        }
    }

    func streamResponse(
        config: ProviderConfig,
        apiKey: String,
        prompt: String,
        conversation: [LLMChatMessage]
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = URL(string: config.baseURL) else {
                        throw ChatAPIError.message("The API endpoint is invalid.")
                    }

                    await prepareConnectionIfNeeded(config: config)

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.httpBody = try LLMRequestBuilder.buildBody(
                        prompt: prompt,
                        conversation: conversation,
                        model: config.model
                    )

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let http = response as? HTTPURLResponse else {
                        throw ChatAPIError.message("Invalid server response.")
                    }

                    var streamed = false
                    var rawLines: [String] = []

                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            streamed = true
                            let payload = String(line.dropFirst(6))
                            if payload == "[DONE]" {
                                break
                            }
                            guard let data = payload.data(using: .utf8) else { continue }
                            if let chunk = try? JSONDecoder().decode(StreamChunk.self, from: data),
                               let content = chunk.choices.first?.delta?.content ?? chunk.choices.first?.message?.content,
                               !content.isEmpty {
                                continuation.yield(content)
                            }
                        } else if !line.isEmpty {
                            rawLines.append(line)
                        }
                    }

                    if !(200 ..< 300).contains(http.statusCode) {
                        let apiBody = rawLines.joined(separator: "\n")
                        throw ChatAPIError.httpStatus(http.statusCode, body: apiBody)
                    }

                    if !streamed {
                        let rawBody = rawLines.joined(separator: "\n")
                        if let data = rawBody.data(using: .utf8),
                           let completion = try? JSONDecoder().decode(FullCompletionResponse.self, from: data),
                           let content = completion.choices.first?.message.content,
                           !content.isEmpty {
                            continuation.yield(content)
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func warmUpLocalNetworkPermissionIfNeeded(for url: URL) async throws {
        guard let host = url.host(percentEncoded: false),
              Self.isLocalNetworkHost(host)
        else {
            return
        }

        let cacheKey = "\(host):\(url.port ?? 80)"
        guard !localNetworkWarmupHosts.contains(cacheKey) else { return }

        try await Self.performLocalNetworkWarmup(host: host, port: url.port ?? Self.defaultPort(for: url))
        localNetworkWarmupHosts.insert(cacheKey)
    }

    private func warmUpGeneralNetworkPermissionIfNeeded(for url: URL) async throws {
        guard let host = url.host(percentEncoded: false) else { return }

        let cacheKey = "\(host):\(url.port ?? Self.defaultPort(for: url))"
        guard !networkWarmupHosts.contains(cacheKey) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 4
        request.cachePolicy = .reloadIgnoringLocalCacheData

        _ = try? await URLSession.shared.data(for: request)
        networkWarmupHosts.insert(cacheKey)
    }

    private static func performLocalNetworkWarmup(host: String, port: Int) async throws {
        let nwHost = NWEndpoint.Host(host)
        guard let nwPort = NWEndpoint.Port(rawValue: UInt16(max(1, min(port, 65_535)))) else { return }

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    let connection = NWConnection(host: nwHost, port: nwPort, using: .tcp)
                    let queue = DispatchQueue(label: "debatecoach.localnetwork.warmup")
                    var resumed = false

                    func finish(_ result: Result<Void, Error>) {
                        guard !resumed else { return }
                        resumed = true
                        connection.cancel()
                        switch result {
                        case .success:
                            continuation.resume()
                        case let .failure(error):
                            continuation.resume(throwing: error)
                        }
                    }

                    connection.stateUpdateHandler = { state in
                        switch state {
                        case .ready, .waiting(_), .failed(_), .cancelled:
                            finish(.success(()))
                        default:
                            break
                        }
                    }

                    connection.start(queue: queue)
                }
            }

            group.addTask {
                try await Task.sleep(for: .seconds(4))
            }

            _ = try await group.next()
            group.cancelAll()
        }
    }

    private static func defaultPort(for url: URL) -> Int {
        if let port = url.port {
            return port
        }
        return url.scheme?.lowercased() == "https" ? 443 : 80
    }

    private static func isLocalNetworkHost(_ host: String) -> Bool {
        let lowercased = host.lowercased()
        if lowercased == "localhost" || lowercased.hasSuffix(".local") {
            return true
        }

        if isPrivateIPv4(lowercased) || isLinkLocalIPv4(lowercased) {
            return true
        }

        if lowercased == "::1" || lowercased.hasPrefix("fe80:") || lowercased.hasPrefix("fd") || lowercased.hasPrefix("fc") {
            return true
        }

        return false
    }

    private static func isPrivateIPv4(_ host: String) -> Bool {
        let parts = host.split(separator: ".").compactMap { Int($0) }
        guard parts.count == 4 else { return false }
        switch (parts[0], parts[1]) {
        case (10, _):
            return true
        case (172, 16 ... 31):
            return true
        case (192, 168):
            return true
        default:
            return false
        }
    }

    private static func isLinkLocalIPv4(_ host: String) -> Bool {
        let parts = host.split(separator: ".").compactMap { Int($0) }
        guard parts.count == 4 else { return false }
        return parts[0] == 169 && parts[1] == 254
    }
}

enum ChatAPIError: LocalizedError {
    case message(String)
    case httpStatus(Int, body: String)

    var errorDescription: String? {
        switch self {
        case let .message(message):
            return message
        case let .httpStatus(status, body):
            let apiMessage = Self.extractAPIMessage(from: body)
            switch status {
            case 401:
                return "Your API Key appears incorrect. Please check and try again."
            case 402:
                return "Your API balance is insufficient. Please top up and try again."
            case 429:
                return "Too many API requests. Please try again later."
            case 500:
                return "API server error. Please try again later."
            default:
                if let apiMessage, !apiMessage.isEmpty {
                    return apiMessage
                }
                return "Request failed with HTTP \(status)."
            }
        }
    }

    private static func extractAPIMessage(from body: String) -> String? {
        guard let data = body.data(using: .utf8),
              let errorEnvelope = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data)
        else {
            return nil
        }
        return errorEnvelope.error.message
    }
}

private struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [LLMChatMessage]
    let temperature: Double
    let maxTokens: Int
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
        case stream
    }
}

private struct StreamChunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable {
            let content: String?
        }

        let delta: Delta?
        let message: Delta?
    }

    let choices: [Choice]
}

private struct FullCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }

        let message: Message
    }

    let choices: [Choice]
}

private struct APIErrorEnvelope: Decodable {
    struct ErrorPayload: Decodable {
        let message: String
    }

    let error: ErrorPayload
}
