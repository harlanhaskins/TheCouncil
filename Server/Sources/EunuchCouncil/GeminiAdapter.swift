import Foundation

public actor GeminiAdapter: AIAdapter {
    public let providerName = "Gemini"
    
    private let apiKey: String
    private let model: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    
    public init(configuration: AIConfiguration) {
        self.apiKey = configuration.apiKey
        self.model = configuration.model ?? "gemini-1.5-pro"
    }
    
    public func sendMessage(_ messages: [AIMessage]) async throws -> AIResponse {
        let urlString = "\(baseURL)/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw AIError.invalidConfiguration
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let geminiContents = messages.map { message -> GeminiContent in
            let role: String
            switch message.role {
            case .user:
                role = "user"
            case .assistant:
                role = "model"
            case .system:
                role = "user"
            }
            
            return GeminiContent(
                role: role,
                parts: [GeminiPart(text: message.content)]
            )
        }
        
        let requestBody = GeminiRequest(
            contents: geminiContents,
            generationConfig: GeminiGenerationConfig(
                maxOutputTokens: 4096,
                temperature: 0.7
            )
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
            if let response = try? decoder.decode(GeminiResponse.self, from: data),
               let firstCandidate = response.candidates.first,
               let firstPart = firstCandidate.content.parts.first {
                
                var usage: TokenUsage?
                if let usageMetadata = response.usageMetadata {
                    usage = TokenUsage(
                        promptTokens: usageMetadata.promptTokenCount,
                        completionTokens: usageMetadata.candidatesTokenCount,
                        totalTokens: usageMetadata.totalTokenCount
                    )
                }
                
                return AIResponse(
                    content: firstPart.text,
                    provider: self.providerName,
                    model: self.model,
                    usage: usage
                )
            }
            
            // Try to decode as error response
            if let errorResponse = try? decoder.decode(GeminiErrorResponse.self, from: data) {
                throw AIError.apiError("Gemini API Error: \(errorResponse.error.message)")
            }
            
            throw AIError.apiError("Invalid response format")
        } catch let error as AIError {
            throw error
        } catch {
            throw AIError.decodingError(error)
        }
    }
}
