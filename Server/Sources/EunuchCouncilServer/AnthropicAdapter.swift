import Foundation

#if os(Linux)
import FoundationNetworking
#endif

public actor AnthropicAdapter: AIAdapter {
    public let providerName = "Anthropic"
    
    private let apiKey: String
    private let model: String
    private let baseURL = "https://api.anthropic.com/v1/messages"
    
    public init(configuration: AIConfiguration) {
        self.apiKey = configuration.apiKey
        self.model = configuration.model ?? "claude-3-5-sonnet-20241022"
    }
    
    public func sendMessage(_ messages: [AIMessage]) async throws -> AIResponse {
        guard let url = URL(string: baseURL) else {
            throw AIError.invalidConfiguration
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let anthropicMessages = messages.compactMap { message -> AnthropicMessage? in
            switch message.role {
            case .user:
                return AnthropicMessage(role: "user", content: message.content)
            case .assistant:
                return AnthropicMessage(role: "assistant", content: message.content)
            case .system:
                return nil
            }
        }
        
        let systemMessage = messages.first { $0.role == .system }?.content
        
        let requestBody = AnthropicRequest(
            model: model,
            maxTokens: 4096,
            messages: anthropicMessages,
            system: systemMessage
        )
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(requestBody)
        } catch {
            throw AIError.decodingError(error)
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        do {
            let decoder = JSONDecoder()
            
            // Try to decode as successful response first
            if let response = try? decoder.decode(AnthropicResponse.self, from: data),
               let firstContent = response.content.first {
                
                var usage: TokenUsage?
                if let anthropicUsage = response.usage {
                    usage = TokenUsage(
                        promptTokens: anthropicUsage.inputTokens,
                        completionTokens: anthropicUsage.outputTokens,
                        totalTokens: anthropicUsage.inputTokens + anthropicUsage.outputTokens
                    )
                }
                
                return AIResponse(
                    content: firstContent.text,
                    provider: self.providerName,
                    model: self.model,
                    usage: usage
                )
            }
            
            // Try to decode as error response
            if let errorResponse = try? decoder.decode(AnthropicErrorResponse.self, from: data) {
                throw AIError.apiError("Anthropic API Error: \(errorResponse.error.message)")
            }
            
            throw AIError.apiError("Invalid response format")
        } catch let error as AIError {
            throw error
        } catch {
            throw AIError.decodingError(error)
        }
    }
}
