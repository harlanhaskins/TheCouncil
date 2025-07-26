import Foundation
import OpenAI

public actor OpenAIAdapter: AIAdapter {
    public let providerName = "OpenAI"

    private let openAI: OpenAI
    private let model: String

    public init(configuration: AIConfiguration) {
        self.openAI = OpenAI(apiToken: configuration.apiKey)
        self.model = configuration.model ?? "gpt-4o"
    }

    public func sendMessage(_ messages: [AIMessage]) async throws -> AIResponse {
        let chatMessages = messages.map { message in
            let role: ChatQuery.ChatCompletionMessageParam
            switch message.role {
            case .user:
                role = .user(.init(content: .string(message.content)))
            case .assistant:
                role = .assistant(.init(content: .textContent(message.content)))
            case .system:
                role = .system(.init(content: .textContent(message.content)))
            }
            return role
        }

        let query = ChatQuery(
            messages: chatMessages,
            model: .chatgpt_4o_latest
        )

        return try await withCheckedThrowingContinuation { continuation in
            _ = openAI.chats(query: query) { [providerName, model] result in
                switch result {
                case .success(let chatResult):
                    guard let choice = chatResult.choices.first,
                          let content = choice.message.content else {
                        continuation.resume(throwing: AIError.apiError("No response content"))
                        return
                    }

                    let usage = chatResult.usage.map { usage in
                        TokenUsage(
                            promptTokens: usage.promptTokens,
                            completionTokens: usage.completionTokens,
                            totalTokens: usage.totalTokens
                        )
                    }

                    let response = AIResponse(
                        content: content,
                        provider: providerName,
                        model: model,
                        usage: usage
                    )
                    continuation.resume(returning: response)

                case .failure(let error):
                    continuation.resume(throwing: AIError.networkError(error))
                }
            }
        }
    }
}
