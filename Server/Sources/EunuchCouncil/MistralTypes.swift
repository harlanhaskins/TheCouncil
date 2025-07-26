import Foundation

// MARK: - Mistral Request Types

public struct MistralRequest: Codable {
    let model: String
    let messages: [MistralMessage]
    let maxTokens: Int?
    let temperature: Double?
    let topP: Double?
    let stream: Bool
    
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens = "max_tokens"
        case temperature
        case topP = "top_p"
        case stream
    }
}

public struct MistralMessage: Codable {
    let role: String
    let content: String
}

// MARK: - Mistral Response Types

public struct MistralResponse: Codable {
    let id: String
    let model: String
    let created: Int
    let usage: MistralUsage
    let object: String
    let choices: [MistralChoice]
}

public struct MistralChoice: Codable {
    let index: Int
    let finishReason: String?
    let message: MistralResponseMessage
    
    enum CodingKeys: String, CodingKey {
        case index
        case finishReason = "finish_reason"
        case message
    }
}

public struct MistralResponseMessage: Codable {
    let role: String
    let content: String
}

public struct MistralUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

public struct MistralError: Codable {
    let message: String
    let type: String?
    let code: String?
}

public struct MistralErrorResponse: Codable {
    let error: MistralError
}