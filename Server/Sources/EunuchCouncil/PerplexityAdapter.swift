import Foundation

public actor PerplexityAdapter: AIAdapter {
    public let providerName = "Perplexity"
    
    private let apiKey: String
    private let model: String
    private let baseURL = "https://api.perplexity.ai/chat/completions"
    
    public init(configuration: AIConfiguration) {
        self.apiKey = configuration.apiKey
        self.model = configuration.model ?? "llama-3.1-sonar-large-128k-online"
    }
    
    public func sendMessage(_ messages: [AIMessage]) async throws -> AIResponse {
        guard let url = URL(string: baseURL) else {
            throw AIError.invalidConfiguration
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let perplexityMessages = messages.map { message -> PerplexityMessage in
            let role: String
            switch message.role {
            case .user:
                role = "user"
            case .assistant:
                role = "assistant"
            case .system:
                role = "system"
            }
            
            return PerplexityMessage(role: role, content: message.content)
        }
        
        let requestBody = PerplexityRequest(
            model: model,
            messages: perplexityMessages,
            maxTokens: 4096,
            temperature: 0.7,
            topP: 0.9,
            returnCitations: true,
            searchDomainFilter: ["perplexity.ai"],
            returnImages: false,
            returnRelatedQuestions: false,
            searchRecencyFilter: "month",
            topK: 0,
            stream: false,
            presencePenalty: 0,
            frequencyPenalty: 1
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
            if let response = try? decoder.decode(PerplexityResponse.self, from: data),
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
            if let errorResponse = try? decoder.decode(PerplexityErrorResponse.self, from: data) {
                throw AIError.apiError("Perplexity API Error: \(errorResponse.error.message)")
            }
            print("Raw response: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            throw AIError.apiError("Invalid response format")
        } catch let error as AIError {
            throw error
        } catch {
            throw AIError.decodingError(error)
        }
    }
}
