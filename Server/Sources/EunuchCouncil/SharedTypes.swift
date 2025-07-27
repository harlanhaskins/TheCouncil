import Foundation

// MARK: - AI Provider Enum

public enum AIProvider: String, Codable, Sendable, CaseIterable {
    case openai = "OpenAI"
    case anthropic = "Anthropic" 
    case gemini = "Gemini"
    case perplexity = "Perplexity"
    case mistral = "Mistral"
    
    public var displayName: String {
        switch self {
        case .openai: return "OpenAI"
        case .anthropic: return "Anthropic"
        case .gemini: return "Gemini"
        case .perplexity: return "Perplexity"
        case .mistral: return "Mistral"
        }
    }
    
    public var faviconURL: String {
        switch self {
        case .openai: return "https://openai.com/favicon.ico"
        case .anthropic: return "https://claude.ai/favicon.ico"
        case .gemini: return "https://www.gstatic.com/lamda/images/gemini_sparkle_4g_512_lt_f94943af3be039176192d.png"
        case .perplexity: return "https://perplexity.ai/favicon.ico"
        case .mistral: return "https://mistral.ai/favicon.ico"
        }
    }
}

// MARK: - Core Data Types

public struct AssistantResult: Codable, Sendable {
    public let id: String
    public let name: String
    public let response: String
    public let timestamp: Int
    public let uuid: String
    public let provider: AIProvider
    
    public init(id: String, name: String, response: String, timestamp: Int, uuid: String, provider: AIProvider) {
        self.id = id
        self.name = name
        self.response = response
        self.timestamp = timestamp
        self.uuid = uuid
        self.provider = provider
    }
}

public struct Advisor: Codable, Sendable {
    public let name: String
    public let title: String
    public let emoji: String
    public let position: Position
    
    public init(name: String, title: String, emoji: String, position: Position) {
        self.name = name
        self.title = title
        self.emoji = emoji
        self.position = position
    }
    
    public struct Position: Codable, Sendable {
        public let x: Double
        public let y: Double
        
        public init(x: Double, y: Double) {
            self.x = x
            self.y = y
        }
    }
}

public struct CouncilState: Codable, Sendable {
    public let results: [AssistantResult]
    public let transcript: String
    public let summary: String
    public let currentRound: Int?
    public let roundTitle: String
    public let isComplete: Bool
    
    public init(results: [AssistantResult] = [], transcript: String = "", summary: String = "", currentRound: Int? = nil, roundTitle: String = "", isComplete: Bool = false) {
        self.results = results
        self.transcript = transcript
        self.summary = summary
        self.currentRound = currentRound
        self.roundTitle = roundTitle
        self.isComplete = isComplete
    }
}

// MARK: - Stream Event Types

public struct StreamEvent: Codable, Sendable {
    public let type: String
    public let data: RawEventData
    
    public init(type: String, data: RawEventData) {
        self.type = type
        self.data = data
    }
}

// Raw JSON data that gets decoded based on the event type
public struct RawEventData: Codable, Sendable {
    // Round started fields
    public let roundNumber: Int?
    public let title: String?
    
    // Advisor response fields  
    public let advisorName: String?
    public let statement: String?
    public let provider: String?
    
    // Transcript/summary fields
    public let transcript: String?
    public let summary: String?
    
    public init(roundNumber: Int? = nil, title: String? = nil, advisorName: String? = nil, statement: String? = nil, provider: String? = nil, transcript: String? = nil, summary: String? = nil) {
        self.roundNumber = roundNumber
        self.title = title
        self.advisorName = advisorName
        self.statement = statement
        self.provider = provider
        self.transcript = transcript
        self.summary = summary
    }
}

// Helper to convert StreamEvent to typed data
public extension StreamEvent {
    var eventData: StreamEventData {
        switch type {
        case "roundStarted":
            return .roundStarted(
                roundNumber: data.roundNumber ?? 0,
                title: data.title ?? ""
            )
        case "advisorResponse":
            let providerString = data.provider ?? ""
            let provider = AIProvider(rawValue: providerString) ?? .openai
            return .advisorResponse(
                advisorName: data.advisorName ?? "",
                statement: data.statement ?? "",
                provider: provider
            )
        case "roundCompleted":
            return .roundCompleted
        case "transcriptGenerated":
            return .transcriptGenerated(transcript: data.transcript ?? "")
        case "summaryGenerated":
            return .summaryGenerated(summary: data.summary ?? "")
        case "sessionCompleted":
            return .sessionCompleted
        default:
            return .roundCompleted // Default fallback
        }
    }
}

public enum StreamEventData: Sendable {
    case roundStarted(roundNumber: Int, title: String)
    case advisorResponse(advisorName: String, statement: String, provider: AIProvider)
    case roundCompleted
    case transcriptGenerated(transcript: String)
    case summaryGenerated(summary: String)
    case sessionCompleted
}

// MARK: - Constants

public struct EunuchCouncilConstants {
    public static let advisors: [Advisor] = [
        Advisor(name: "Zafir", title: "the Scheming Vizier", emoji: "⚔️", position: Advisor.Position(x: 5, y: 85)),
        Advisor(name: "Malik", title: "the Grand Treasurer", emoji: "💰", position: Advisor.Position(x: 20, y: 80)),
        Advisor(name: "Lorenzo", title: "the Court Philosopher", emoji: "📚", position: Advisor.Position(x: 35, y: 75)),
        Advisor(name: "Farid", title: "the Spymaster", emoji: "👁️", position: Advisor.Position(x: 65, y: 75)),
        Advisor(name: "Edmund", title: "the War Strategist", emoji: "⚔️", position: Advisor.Position(x: 80, y: 80)),
        Advisor(name: "Benedict", title: "the Trade Minister", emoji: "📦", position: Advisor.Position(x: 95, y: 85)),
        Advisor(name: "Godwin", title: "the Peacemaker", emoji: "🕊️", position: Advisor.Position(x: 90, y: 45)),
        Advisor(name: "Marcus", title: "the Traditionalist", emoji: "📜", position: Advisor.Position(x: 75, y: 15)),
        Advisor(name: "Rodrigo", title: "the Court Gossip", emoji: "💬", position: Advisor.Position(x: 55, y: 5)),
        Advisor(name: "Alistair", title: "the Mystic", emoji: "🔮", position: Advisor.Position(x: 45, y: 5)),
        Advisor(name: "Saeed", title: "the Contrarian", emoji: "🌪️", position: Advisor.Position(x: 25, y: 15)),
        Advisor(name: "Abbas", title: "the Silent Observer", emoji: "🤫", position: Advisor.Position(x: 10, y: 45))
    ]
    
}