import Foundation

// MARK: - Gemini Request Types

public struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
    
    enum CodingKeys: String, CodingKey {
        case contents
        case generationConfig
    }
}

public struct GeminiContent: Codable {
    let role: String
    let parts: [GeminiPart]
}

public struct GeminiPart: Codable {
    let text: String
}

public struct GeminiGenerationConfig: Codable {
    let maxOutputTokens: Int
    let temperature: Double
    
    enum CodingKeys: String, CodingKey {
        case maxOutputTokens = "maxOutputTokens"
        case temperature
    }
}

// MARK: - Gemini Response Types

public struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
    let usageMetadata: GeminiUsageMetadata?
    
    enum CodingKeys: String, CodingKey {
        case candidates
        case usageMetadata
    }
}

public struct GeminiCandidate: Codable {
    let content: GeminiContent
    let finishReason: String?
    let index: Int?
    let safetyRatings: [GeminiSafetyRating]?
    
    enum CodingKeys: String, CodingKey {
        case content
        case finishReason
        case index
        case safetyRatings
    }
}

public struct GeminiSafetyRating: Codable {
    let category: String
    let probability: String
}

public struct GeminiUsageMetadata: Codable {
    let promptTokenCount: Int
    let candidatesTokenCount: Int
    let totalTokenCount: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokenCount
        case candidatesTokenCount
        case totalTokenCount
    }
}

public struct GeminiError: Codable {
    let code: Int
    let message: String
    let status: String
}

public struct GeminiErrorResponse: Codable {
    let error: GeminiError
}