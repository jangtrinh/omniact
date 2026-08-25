import Foundation

public enum LLMError: LocalizedError, Sendable {
    case invalidURL
    case missingAPIKey
    case networkError(String)
    case apiError(status: Int, message: String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API Endpoint URL"
        case .missingAPIKey:
            return "API Key is missing for this provider"
        case .networkError(let msg):
            return "Network Error: \(msg)"
        case .apiError(let status, let rawMsg):
            if let data = rawMsg.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errObj = json["error"] as? [String: Any],
               let message = errObj["message"] as? String {
                return "\(message) (HTTP \(status))"
            }
            return "API Error (\(status)): \(rawMsg)"
        case .cancelled:
            return "Request was cancelled"
        }
    }
}

public final class LLMClient: Sendable {
    public static let shared = LLMClient()

    private init() {}

    private func normalizeBaseURL(_ url: String) -> String {
        var base = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if base.hasSuffix("/chat/completions") {
            base = String(base.dropLast("/chat/completions".count))
        }
        if base.hasSuffix("/models") {
            base = String(base.dropLast("/models".count))
        }
        if base.hasSuffix("/") {
            base = String(base.dropLast(1))
        }
        return base
    }

    public func streamCompletion(
        prompt: String,
        systemPrompt: String? = nil,
        config: LLMConfiguration
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let endpoint = "\(normalizeBaseURL(config.baseURL))/chat/completions"

                    guard let url = URL(string: endpoint) else {
                        continuation.finish(throwing: LLMError.invalidURL)
                        return
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

                    if let key = config.apiKey, !key.isEmpty {
                        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
                    }

                    var messages: [[String: String]] = []
                    if let sys = systemPrompt, !sys.isEmpty {
                        messages.append(["role": "system", "content": sys])
                    }
                    messages.append(["role": "user", "content": prompt])

                    let body: [String: Any] = [
                        "model": config.model,
                        "messages": messages,
                        "temperature": config.temperature,
                        "stream": true
                    ]

                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                        var errorBody = ""
                        for try await line in bytes.lines {
                            errorBody += line
                        }
                        continuation.finish(throwing: LLMError.apiError(status: httpResponse.statusCode, message: errorBody))
                        return
                    }

                    for try await line in bytes.lines {
                        if Task.isCancelled {
                            continuation.finish(throwing: LLMError.cancelled)
                            return
                        }

                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty || trimmed == "data: [DONE]" {
                            continue
                        }

                        if trimmed.hasPrefix("data: ") {
                            let jsonString = String(trimmed.dropFirst(6))
                            if let data = jsonString.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let choices = json["choices"] as? [[String: Any]],
                               let first = choices.first,
                               let delta = first["delta"] as? [String: Any],
                               let content = delta["content"] as? String {
                                continuation.yield(content)
                            }
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    public func fetchAvailableModels(baseURL: String, apiKey: String?) async throws -> [String] {
        let modelsEndpoint = "\(normalizeBaseURL(baseURL))/models"

        guard let url = URL(string: modelsEndpoint) else {
            throw LLMError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 8
        if let key = apiKey, !key.isEmpty {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw LLMError.apiError(status: http.statusCode, message: errorMsg)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]] else {
            return []
        }

        return dataArray.compactMap { $0["id"] as? String }.sorted()
    }
}
