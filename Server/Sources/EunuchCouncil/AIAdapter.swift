import Foundation

public struct AIMessage: Sendable {
    public let content: String
    public let role: MessageRole
    
    public enum MessageRole: Sendable {
        case user
        case assistant
        case system
    }
    
    public init(content: String, role: MessageRole) {
        self.content = content
        self.role = role
    }
}

public struct AIResponse: Sendable {
    public let content: String
    public let provider: String
    public let model: String?
    public let usage: TokenUsage?
    
    public init(content: String, provider: String, model: String? = nil, usage: TokenUsage? = nil) {
        self.content = content
        self.provider = provider
        self.model = model
        self.usage = usage
    }
}

public struct TokenUsage: Sendable {
    public let promptTokens: Int?
    public let completionTokens: Int?
    public let totalTokens: Int?
    
    public init(promptTokens: Int? = nil, completionTokens: Int? = nil, totalTokens: Int? = nil) {
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = totalTokens
    }
}

public struct AIConfiguration: Sendable, Codable {
    public let provider: String
    public let apiKey: String
    public let model: String?
    public let maxTokens: Int?
    public let temperature: Double?
    
    public init(provider: String, apiKey: String, model: String? = nil, maxTokens: Int? = nil, temperature: Double? = nil) {
        self.provider = provider
        self.apiKey = apiKey
        self.model = model
        self.maxTokens = maxTokens
        self.temperature = temperature
    }
}

public enum AIError: Error {
    case invalidConfiguration
    case networkError(Error)
    case apiError(String)
    case decodingError(Error)
    case notImplemented
}

public protocol AIAdapter: Sendable {
    var providerName: String { get }
    
    init(configuration: AIConfiguration)
    
    func sendMessage(_ messages: [AIMessage]) async throws -> AIResponse
}

public extension AIAdapter {
    func sendPrompt(_ prompt: String) async throws -> AIResponse {
        let message = AIMessage(content: prompt, role: .user)
        return try await sendMessage([message])
    }
}
