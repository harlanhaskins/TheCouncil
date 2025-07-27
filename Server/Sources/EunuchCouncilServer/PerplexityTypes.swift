import Foundation

#if os(Linux)
import FoundationNetworking
#endif

// MARK: - Perplexity Request Types

public struct PerplexityRequest: Codable {
    let model: String
    let messages: [PerplexityMessage]
    let maxTokens: Int
    let temperature: Double
    let topP: Double
    let returnCitations: Bool
    let searchDomainFilter: [String]
    let returnImages: Bool
    let returnRelatedQuestions: Bool
    let searchRecencyFilter: String
    let topK: Int
    let stream: Bool
    let presencePenalty: Double
    let frequencyPenalty: Double
    
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens = "max_tokens"
        case temperature
        case topP = "top_p"
        case returnCitations = "return_citations"
        case searchDomainFilter = "search_domain_filter"
        case returnImages = "return_images"
        case returnRelatedQuestions = "return_related_questions"
        case searchRecencyFilter = "search_recency_filter"
        case topK = "top_k"
        case stream
        case presencePenalty = "presence_penalty"
        case frequencyPenalty = "frequency_penalty"
    }
}

public struct PerplexityMessage: Codable {
    let role: String
    let content: String
}

// MARK: - Perplexity Response Types

public struct PerplexityResponse: Codable {
    let id: String
    let model: String
    let created: Int
    let usage: PerplexityUsage
    let object: String
    let choices: [PerplexityChoice]
}

public struct PerplexityChoice: Codable {
    let index: Int
    let finishReason: String
    let message: PerplexityResponseMessage
    let delta: PerplexityDelta?
    
    enum CodingKeys: String, CodingKey {
        case index
        case finishReason = "finish_reason"
        case message
        case delta
    }
}

public struct PerplexityResponseMessage: Codable {
    let role: String
    let content: String
}

public struct PerplexityDelta: Codable {
    let role: String?
    let content: String?
}

public struct PerplexityUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

public struct PerplexityError: Codable {
    let message: String
    let type: String
    let param: String?
    let code: String?
}

public struct PerplexityErrorResponse: Codable {
    let error: PerplexityError
}
