import Foundation

#if os(Linux)
import FoundationNetworking
#endif

// MARK: - Anthropic Request Types

public struct AnthropicRequest: Codable {
    let model: String
    let maxTokens: Int
    let messages: [AnthropicMessage]
    let system: String?
    
    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
        case system
    }
}

public struct AnthropicMessage: Codable {
    let role: String
    let content: String
}

// MARK: - Anthropic Response Types

public struct AnthropicResponse: Codable {
    let id: String?
    let type: String?
    let role: String?
    let content: [AnthropicContent]
    let model: String?
    let stopReason: String?
    let stopSequence: String?
    let usage: AnthropicUsage?
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case role
        case content
        case model
        case stopReason = "stop_reason"
        case stopSequence = "stop_sequence"
        case usage
    }
}

public struct AnthropicContent: Codable {
    let type: String
    let text: String
}

public struct AnthropicUsage: Codable {
    let inputTokens: Int
    let outputTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

public struct AnthropicError: Codable {
    let type: String
    let message: String
}

public struct AnthropicErrorResponse: Codable {
    let error: AnthropicError
}
