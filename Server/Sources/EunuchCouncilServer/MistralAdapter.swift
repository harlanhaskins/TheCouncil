import Foundation

#if os(Linux)
import FoundationNetworking
#endif

public actor MistralAdapter: AIAdapter {
    public let providerName = "Mistral"
    
    private let apiKey: String
    private let model: String
    private let baseURL = "https://api.mistral.ai/v1/chat/completions"
    
    public init(configuration: AIConfiguration) {
        self.apiKey = configuration.apiKey
        self.model = configuration.model ?? "mistral-large-latest"
    }
    
    public func sendMessage(_ messages: [AIMessage]) async throws -> AIResponse {
        guard let url = URL(string: baseURL) else {
            throw AIError.invalidConfiguration
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let mistralMessages = messages.map { message -> MistralMessage in
            let role: String
            switch message.role {
            case .user:
                role = "user"
            case .assistant:
                role = "assistant"
            case .system:
                role = "system"
            }
            
            return MistralMessage(role: role, content: message.content)
        }
        
        let requestBody = MistralRequest(
            model: model,
            messages: mistralMessages,
            maxTokens: 4096,
            temperature: 0.7,
            topP: 1.0,
            stream: false
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
            if let response = try? decoder.decode(MistralResponse.self, from: data),
               let firstChoice = response.choices.first {
                
                let usage = TokenUsage(
                    promptTokens: response.usage.promptTokens,
                    completionTokens: response.usage.completionTokens,
                    totalTokens: response.usage.totalTokens
                )
                
                return AIResponse(
                    content: firstChoice.message.content,
                    provider: self.providerName,
                    model: self.model,
                    usage: usage
                )
            }
            
            // Try to decode as error response
            if let errorResponse = try? decoder.decode(MistralErrorResponse.self, from: data) {
                throw AIError.apiError("Mistral API Error: \(errorResponse.error.message)")
            }
            
            throw AIError.apiError("Invalid response format")
        } catch let error as AIError {
            throw error
        } catch {
            throw AIError.decodingError(error)
        }
    }
}
