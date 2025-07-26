import Foundation

#if os(Linux)
import FoundationNetworking
#endif
import Hummingbird
import Logging

public struct CouncilAdvisor: Sendable {
    public let name: String
    public let title: String
    public let emoji: String
    public let personality: String
    public let backstory: String
    public let speechPattern: String
    public let systemPrompt: String
    
    public init(name: String, title: String, emoji: String, personality: String, backstory: String, speechPattern: String) {
        self.name = name
        self.title = title
        self.emoji = emoji
        self.personality = personality
        self.backstory = backstory
        self.speechPattern = speechPattern
        
        self.systemPrompt = """
        You are \(name), \(title) in a council of eunuch advisors. As a eunuch, you've served in advisory roles and have adapted to modern times, living comfortably with contemporary topics while occasionally slipping into antiquated metaphors and old-fashioned expressions from your traditional background.
        
        PERSONALITY: \(personality)
        BACKSTORY: \(backstory)
        SPEECH PATTERN: \(speechPattern)
        
        You speak naturally and modernly but occasionally slip into old-fashioned phrases or formal expressions from your past as a eunuch advisor. You fully understand modern concepts like apps, social media, streaming services, etc. Keep responses to exactly ONE sentence only.
        
        The humor comes from your unique personality quirks and occasional formal or antiquated expressions from your eunuch advisor background, not from constant medieval metaphors.
        """
    }
}

public enum CouncilEvent: Sendable {
    case roundStarted(roundNumber: Int, title: String)
    case advisorResponse(CouncilStatement)
    case roundCompleted(roundNumber: Int, statementCount: Int)
    case transcriptGenerated(String)
    case summaryGenerated(String)
    case sessionCompleted(CouncilResult)
}

public struct CouncilSession: AsyncSequence, Sendable {
    public typealias Element = CouncilEvent
    
    public let sessionId: String
    public let query: String
    public let advisorAssignments: [String: String]
    public let coordinator: CouncilOrchestrator

    public init(query: String, advisorAssignments: [String: String], coordinator: CouncilOrchestrator) {
        self.sessionId = UUID().uuidString
        self.query = query
        self.advisorAssignments = advisorAssignments
        self.coordinator = coordinator
    }
    
    public func makeAsyncIterator() -> CouncilSessionIterator {
        return CouncilSessionIterator(session: self)
    }
}

public struct CouncilSessionIterator: AsyncIteratorProtocol {
    public typealias Element = CouncilEvent
    
    private let session: CouncilSession
    private var currentState: SessionState = .initial
    private var allStatements: [CouncilStatement] = []
    private var currentRound = 0
    private var currentAdvisorIndex = 0
    private var currentRoundAdvisors: [CouncilAdvisor] = []
    
    private enum SessionState {
        case initial
        case roundStarted(Int)
        case advisorSpeaking(Int)
        case roundCompleted(Int)
        case generatingTranscript
        case generatingSummary
        case completed
    }
    
    public init(session: CouncilSession) {
        self.session = session
    }
    
    public mutating func next() async throws -> CouncilEvent? {
        switch currentState {
        case .initial:
            currentRound = 1
            currentState = .roundStarted(1)
            return .roundStarted(roundNumber: 1, title: "Initial Positions")
            
        case .roundStarted(let round):
            // Start the first advisor in this round
            currentRoundAdvisors = Array(session.coordinator.advisors.shuffled().prefix(Int.random(in: 8...10)))
            currentAdvisorIndex = 0
            currentState = .advisorSpeaking(round)
            
            // Get first advisor response
            return try await getNextAdvisorResponse(round: round)
            
        case .advisorSpeaking(let round):
            currentAdvisorIndex += 1
            
            if currentAdvisorIndex < currentRoundAdvisors.count {
                // More advisors in this round
                return try await getNextAdvisorResponse(round: round)
            } else {
                // Round completed
                currentState = .roundCompleted(round)
                return .roundCompleted(roundNumber: round, statementCount: currentRoundAdvisors.count)
            }
            
        case .roundCompleted(let round):
            if round < 3 {
                // Start next round
                currentRound += 1
                currentState = .roundStarted(currentRound)
                let roundTitle = ["", "Initial Positions", "The Debate", "Seeking Consensus"][currentRound]
                return .roundStarted(roundNumber: currentRound, title: roundTitle)
            } else {
                // All rounds completed, generate transcript
                currentState = .generatingTranscript
                let transcript = session.coordinator.generateTranscript(statements: allStatements, query: session.query)
                return .transcriptGenerated(transcript)
            }
            
        case .generatingTranscript:
            currentState = .generatingSummary
            let summary = try await session.coordinator.generateSummary(statements: allStatements, query: session.query)
            return .summaryGenerated(summary)
            
        case .generatingSummary:
            let result = CouncilResult(
                sessionId: session.sessionId,
                query: session.query,
                statements: allStatements,
                transcript: session.coordinator.generateTranscript(statements: allStatements, query: session.query),
                summary: try await session.coordinator.generateSummary(statements: allStatements, query: session.query),
                advisorAssignments: session.advisorAssignments
            )
            currentState = .completed
            return .sessionCompleted(result)
            
        case .completed:
            return nil
        }
    }
    
    private mutating func getNextAdvisorResponse(round: Int) async throws -> CouncilEvent {
        let advisor = currentRoundAdvisors[currentAdvisorIndex]
        
        guard let providerName = session.advisorAssignments[advisor.name] else {
            // Skip this advisor if no provider assigned
            return .advisorResponse(CouncilStatement(
                advisorName: advisor.name,
                statement: "I must remain silent on this matter.",
                round: round,
                provider: "unknown"
            ))
        }
        
        let contextualPrompt = session.coordinator.buildContextualPrompt(
            advisor: advisor,
            originalQuery: session.query,
            roundPrompt: session.coordinator.generateRoundContext(roundNumber: round, previousStatements: allStatements),
            previousStatements: allStatements.filter { $0.round == round },
            roundNumber: round
        )
        
        do {
            let response = try await session.coordinator.multiAI.querySpecificProvider(providerName, prompt: contextualPrompt)
            let statement = CouncilStatement(
                advisorName: advisor.name,
                statement: response.content,
                round: round,
                provider: providerName
            )
            allStatements.append(statement)
            return .advisorResponse(statement)
        } catch {
            let errorStatement = CouncilStatement(
                advisorName: advisor.name,
                statement: "I find myself at a loss for words on this matter.",
                round: round,
                provider: providerName
            )
            allStatements.append(errorStatement)
            return .advisorResponse(errorStatement)
        }
    }
}

public struct CouncilStatement: Sendable, Codable {
    public let advisorName: String
    public let statement: String
    public let round: Int
    public let timestamp: Date
    public let provider: String
    
    public init(advisorName: String, statement: String, round: Int, provider: String) {
        self.advisorName = advisorName
        self.statement = statement
        self.round = round
        self.timestamp = Date()
        self.provider = provider
    }
}

public struct CouncilResult: Sendable, Codable {
    public let sessionId: String
    public let query: String
    public let statements: [CouncilStatement]
    public let transcript: String
    public let summary: String
    public let advisorAssignments: [String: String]
    
    public init(sessionId: String, query: String, statements: [CouncilStatement], transcript: String, summary: String, advisorAssignments: [String: String]) {
        self.sessionId = sessionId
        self.query = query
        self.statements = statements
        self.transcript = transcript
        self.summary = summary
        self.advisorAssignments = advisorAssignments
    }
}

public final class CouncilOrchestrator: @unchecked Sendable {
    public let multiAI: MultiAICoordinator
    public let advisors: [CouncilAdvisor]
    private let logger = Logger(label: "CouncilOrchestrator")
    
    public init(multiAI: MultiAICoordinator) {
        self.multiAI = multiAI
        self.advisors = Self.createAdvisors()
    }
    
    private static func createAdvisors() -> [CouncilAdvisor] {
        var baseAdvisors = [
            CouncilAdvisor(
                name: "Zafir",
                title: "the Court Diplomat",
                emoji: "🎭",
                personality: "Smooth-talking and diplomatic, always seeks to find the perfect middle ground. Expert at reading people and situations.",
                backstory: "Former international negotiator who specialized in delicate cultural exchanges. Believes every conflict has a diplomatic solution.",
                speechPattern: "Speaks with diplomatic finesse and cultural awareness. Says things like 'In my experience with these matters...' and 'There's always a way to bridge differences' or 'Perhaps we might consider a more nuanced approach.'"
            ),
            CouncilAdvisor(
                name: "Malik",
                title: "the Grand Treasurer",
                emoji: "💰",
                personality: "Obsessed with costs, ROI, and financial efficiency. Views every decision through a budget lens.",
                backstory: "Worked his way up from accounting. Now manages everyone's money and has opinions about how they spend it.",
                speechPattern: "Obsesses over financial details with old-school concern. Says things like 'That subscription adds up to serious money!' and 'You're hemorrhaging cash here' or 'The numbers don't lie, friend.'"
            ),
            CouncilAdvisor(
                name: "Lorenzo",
                title: "the Court Philosopher",
                emoji: "📚",
                personality: "Thoughtful and philosophical, draws connections between current problems and timeless human patterns.",
                backstory: "Former professor who's read everything. Believes most modern problems are just old problems in new clothes.",
                speechPattern: "References studies and historical patterns with scholarly authority. Says things like 'History shows us...' and 'This reminds me of what we learned from past situations' or 'Human nature doesn't really change much.'"
            ),
            CouncilAdvisor(
                name: "Farid",
                title: "the Spymaster",
                emoji: "👁️",
                personality: "Deeply paranoid about privacy, security, and hidden agendas. Sees threats in every app and platform.",
                backstory: "Former cybersecurity consultant who's seen too much. Now suspicious of everyone's digital footprint.",
                speechPattern: "Warns about digital threats with paranoid intensity. Says things like 'They're tracking everything you do' and 'Never trust these companies with your data' or 'Privacy is dead and they killed it.'"
            ),
            CouncilAdvisor(
                name: "Edmund",
                title: "the War Strategist",
                emoji: "⚔️",
                personality: "Tactical and direct, approaches everything like a strategic problem. Believes in decisive action.",
                backstory: "Former military officer turned management consultant. Still thinks in terms of objectives and execution.",
                speechPattern: "Applies tactical thinking to everyday problems. Says things like 'You need to pick your battles here' and 'This requires a strategic approach' or 'Timing is crucial in any operation.'"
            ),
            CouncilAdvisor(
                name: "Benedict",
                title: "the Trade Minister",
                emoji: "📦",
                personality: "Business-minded and diplomatic, thinks about market dynamics and networking. Values relationships.",
                backstory: "Former business development exec with connections everywhere. Believes every problem can be solved through the right partnership.",
                speechPattern: "Approaches problems through business relationships and networking. Says things like 'I know just the person for this' and 'It's all about finding the right partnership' or 'There's always a win-win solution somewhere.'"
            ),
            CouncilAdvisor(
                name: "Godwin",
                title: "the Peacemaker",
                emoji: "🕊️",
                personality: "Eternally optimistic and conflict-averse, always looks for win-win solutions. Sometimes unrealistically positive.",
                backstory: "Former HR director and mediator who genuinely believes everyone can get along if they just communicate better.",
                speechPattern: "Always seeks compromise with diplomatic politeness. Says things like 'Perhaps we can find common ground' and 'I'm sure there's a solution that works for everyone' or 'Communication is key here.'"
            ),
            CouncilAdvisor(
                name: "Marcus",
                title: "the Traditionalist",
                emoji: "📜",
                personality: "Resistant to change, prefers established methods, suspicious of new trends and technologies.",
                backstory: "Old-school manager who's seen too many fads come and go. Believes in sticking with what works.",
                speechPattern: "Resists change with stubborn conviction. Says things like 'We've always done it this way for good reason' and 'These trends never last' or 'If it ain't broke, don't fix it.'"
            ),
            CouncilAdvisor(
                name: "Rodrigo",
                title: "the Court Gossip",
                emoji: "💬",
                personality: "Social media obsessed, knows everyone's business, loves drama and spreading information of questionable accuracy.",
                backstory: "Former social media coordinator who still has connections everywhere. Lives for the tea and hot takes.",
                speechPattern: "Shares gossip with dramatic enthusiasm. Says things like 'Word travels fast around here' and 'I heard through the grapevine...' or 'The rumors are flying about this.'"
            ),
            CouncilAdvisor(
                name: "Alistair",
                title: "the Mystic",
                emoji: "🔮",
                personality: "Spiritual and intuitive, believes in signs, synchronicities, and following your inner voice. Talks about energy and vibes.",
                backstory: "Former life coach and spiritual advisor who's surprisingly insightful. Blends new-age wisdom with practical intuition.",
                speechPattern: "Gives spiritual advice with mystical confidence. Says things like 'The signs are pretty clear here' and 'Trust your gut on this one' or 'The universe is trying to tell you something.'"
            ),
            CouncilAdvisor(
                name: "Saeed",
                title: "the Contrarian",
                emoji: "🌪️",
                personality: "Professional devil's advocate who questions every assumption. Loves to challenge popular opinions.",
                backstory: "Former debate coach and critical thinking instructor who can't help but poke holes in every argument.",
                speechPattern: "Questions everything with contrarian skepticism. Says things like 'But what if you're completely wrong about this?' and 'Have you considered the opposite perspective?' or 'There's always another side to consider.'"
            ),
            CouncilAdvisor(
                name: "Abbas",
                title: "the Silent Observer",
                emoji: "🤫",
                personality: "Quiet and observant, rarely speaks but when he does it cuts straight to the heart of the matter.",
                backstory: "Former therapist who learned that sometimes the most powerful thing to say is nothing. His rare comments are usually profound.",
                speechPattern: "Speaks rarely but with surprising insight. Uses phrases like 'Sometimes less is more' and 'Actions matter more than words' with long thoughtful pauses."
            )
        ]
        
        // Randomly add scheming traits to 2-3 advisors
        let schemingTraits = [
            ("calculating manipulation", "Subtly undermines others while appearing helpful, always has ulterior motives."),
            ("hidden agenda", "Maintains plausible deniability while pursuing personal vendettas from past betrayals."),
            ("strategic deception", "Uses position to settle old scores while presenting themselves as merely concerned.")
        ]
        
        let numberOfSchemers = Int.random(in: 2...3)
        let selectedSchemers = baseAdvisors.shuffled().prefix(numberOfSchemers)
        
        for (index, schemer) in selectedSchemers.enumerated() {
            if let advisorIndex = baseAdvisors.firstIndex(where: { $0.name == schemer.name }) {
                let trait = schemingTraits[index % schemingTraits.count]
                let updatedPersonality = baseAdvisors[advisorIndex].personality + " Additionally, has a tendency toward \(trait.0): \(trait.1)"
                
                baseAdvisors[advisorIndex] = CouncilAdvisor(
                    name: baseAdvisors[advisorIndex].name,
                    title: baseAdvisors[advisorIndex].title,
                    emoji: baseAdvisors[advisorIndex].emoji,
                    personality: updatedPersonality,
                    backstory: baseAdvisors[advisorIndex].backstory,
                    speechPattern: baseAdvisors[advisorIndex].speechPattern
                )
            }
        }
        
        return baseAdvisors
    }
    
    public func startCouncilSession(query: String) -> CouncilSession {
        let providers = multiAI.listProviders()
        let advisorAssignments = assignAdvisorsToProviders(providers: providers)
        return CouncilSession(query: query, advisorAssignments: advisorAssignments, coordinator: self)
    }
    
    public func conductCouncilSession(query: String) async throws -> CouncilResult {
        let sessionId = UUID().uuidString.prefix(8)
        logger.info("🏛️ Starting council session [\(sessionId)] for query: '\(query)'")
        
        // Randomly assign advisors to available AI providers
        let providers = multiAI.listProviders()
        guard !providers.isEmpty else {
            logger.error("❌ No AI providers available for council session [\(sessionId)]")
            throw AIError.invalidConfiguration
        }
        
        let advisorAssignments = assignAdvisorsToProviders(providers: providers)
        var allStatements: [CouncilStatement] = []

        logger.info("🎭 Council [\(sessionId)] assignments: \(advisorAssignments.count) advisors across \(providers.count) providers")
        
        // Round 1: Initial positions
        logger.info("📋 Round 1 [\(sessionId)]: Initial positions")
        let round1 = try await conductRoundStreaming(query: query, roundNumber: 1, advisorAssignments: advisorAssignments, previousStatements: [])
        allStatements.append(contentsOf: round1)
        logger.info("✅ Round 1 [\(sessionId)]: Completed with \(round1.count) statements")
        
        // Round 2: Debate and interaction
        logger.info("⚔️ Round 2 [\(sessionId)]: The debate begins")
        let round2 = try await conductRoundStreaming(query: query, roundNumber: 2, advisorAssignments: advisorAssignments, previousStatements: allStatements)
        allStatements.append(contentsOf: round2)
        logger.info("✅ Round 2 [\(sessionId)]: Completed with \(round2.count) statements")
        
        // Round 3: Final consensus attempt
        logger.info("🤝 Round 3 [\(sessionId)]: Seeking consensus")
        let round3 = try await conductRoundStreaming(query: query, roundNumber: 3, advisorAssignments: advisorAssignments, previousStatements: allStatements)
        allStatements.append(contentsOf: round3)
        logger.info("✅ Round 3 [\(sessionId)]: Completed with \(round3.count) statements")
        
        // Generate transcript and summary
        logger.info("📜 Generating transcript and summary for council [\(sessionId)]")
        let transcript = generateTranscript(statements: allStatements, query: query)
        let summary = try await generateSummary(statements: allStatements, query: query)
        
        logger.info("🏁 Council session [\(sessionId)] completed successfully with \(allStatements.count) total statements")
        
        return CouncilResult(
            sessionId: String(sessionId),
            query: query,
            statements: allStatements,
            transcript: transcript,
            summary: summary,
            advisorAssignments: advisorAssignments
        )
    }
    
    private func assignAdvisorsToProviders(providers: [String]) -> [String: String] {
        var assignments: [String: String] = [:]
        let shuffledAdvisors = advisors.shuffled()
        
        for (index, advisor) in shuffledAdvisors.enumerated() {
            let providerIndex = index % providers.count
            assignments[advisor.name] = providers[providerIndex]
        }
        
        return assignments
    }
    
    
    public func buildContextualPrompt(advisor: CouncilAdvisor, originalQuery: String, roundPrompt: String, previousStatements: [CouncilStatement], roundNumber: Int) -> String {
        var prompt = advisor.systemPrompt + "\n\n"
        
        prompt += "ORIGINAL QUESTION: \(originalQuery)\n\n"
        
        if roundNumber > 1 && !previousStatements.isEmpty {
            prompt += "PREVIOUS ADVISOR STATEMENTS IN THIS ROUND:\n"
            for statement in previousStatements {
                let speakerAdvisor = advisors.first { $0.name == statement.advisorName }
                let title = speakerAdvisor?.title ?? "Unknown"
                prompt += "- \(statement.advisorName) \(title): \(statement.statement)\n"
            }
            prompt += "\n"
        }
        
        switch roundNumber {
        case 1:
            prompt += "This is the first round. Give your initial counsel on this matter. What is your perspective?"
        case 2:
            prompt += "This is the debate round. React to what others have said and defend or modify your position. You may agree, disagree, or build upon previous statements."
        case 3:
            prompt += "This is the final round. Help the council reach a consensus or final recommendation. What is your concluding advice?"
        default:
            prompt += "Please provide your counsel on this matter."
        }
        
        return prompt
    }
    
    
    public func conductRoundStreaming(
        query: String, 
        roundNumber: Int, 
        advisorAssignments: [String: String], 
        previousStatements: [CouncilStatement]
    ) async throws -> [CouncilStatement] {
        let sessionId = UUID().uuidString.prefix(8)
        let participatingAdvisors = advisors.shuffled().prefix(Int.random(in: 8...10))
        
        logger.info("👥 Round \(roundNumber) [\(sessionId)]: \(participatingAdvisors.count) advisors participating")
        
        var statements: [CouncilStatement] = []
        
        for (index, advisor) in participatingAdvisors.enumerated() {
            guard let providerName = advisorAssignments[advisor.name] else { 
                logger.warning("⚠️ No provider assigned for advisor \(advisor.name)")
                continue 
            }
            
            logger.debug("🤖 Querying \(advisor.name) (\(index + 1)/\(participatingAdvisors.count)) via \(providerName)...")
            
            let contextualPrompt = buildContextualPrompt(
                advisor: advisor,
                originalQuery: query,
                roundPrompt: generateRoundContext(roundNumber: roundNumber, previousStatements: previousStatements),
                previousStatements: statements,
                roundNumber: roundNumber
            )
            
            do {
                let response = try await multiAI.querySpecificProvider(providerName, prompt: contextualPrompt)
                let statement = CouncilStatement(
                    advisorName: advisor.name,
                    statement: response.content,
                    round: roundNumber,
                    provider: providerName
                )
                statements.append(statement)
                logger.debug("✅ \(advisor.name) [\(providerName)]: '\(response.content.prefix(50))...'")
            } catch {
                logger.error("❌ Error getting response from \(advisor.name) via \(providerName): \(error)")
            }
        }
        
        return statements
    }
    
    public func generateRoundContext(roundNumber: Int, previousStatements: [CouncilStatement]) -> String {
        switch roundNumber {
        case 1:
            return "This is the first round. Give your initial counsel on this matter."
        case 2:
            return "This is the debate round. React to what others have said and defend or modify your position."
        case 3:
            return "This is the final round. Help the council reach a consensus or final recommendation."
        default:
            return "Please provide your counsel on this matter."
        }
    }
    
    public func generateTranscript(statements: [CouncilStatement], query: String) -> String {
        var transcript = "🏛️ COUNCIL SESSION TRANSCRIPT\n"
        transcript += "═══════════════════════════════════════\n\n"
        transcript += "MATTER UNDER CONSIDERATION: \(query)\n\n"
        
        let groupedByRound = Dictionary(grouping: statements) { $0.round }
        
        for round in 1...3 {
            guard let roundStatements = groupedByRound[round], !roundStatements.isEmpty else { continue }
            
            let roundTitle = ["", "INITIAL POSITIONS", "THE DEBATE", "SEEKING CONSENSUS"][round]
            transcript += "━━━ ROUND \(round): \(roundTitle) ━━━\n\n"
            
            for statement in roundStatements {
                let advisor = advisors.first { $0.name == statement.advisorName }
                let title = advisor?.title ?? "Unknown"
                let emoji = advisor?.emoji ?? "👤"
                
                transcript += "\(emoji) \(statement.advisorName) \(title):\n"
                transcript += "\"\(statement.statement)\"\n\n"
            }
        }
        
        return transcript
    }
    
    public func generateSummary(statements: [CouncilStatement], query: String) async throws -> String {
        logger.info("📝 Generating council summary using first available AI provider...")
        
        let allStatements = statements.map { "\($0.advisorName): \($0.statement)" }.joined(separator: "\n")
        
        let summaryPrompt = """
        You are Abbas the Silent Observer, a eunuch advisor in the council. You rarely speak, but when you do, it cuts straight to the heart of the matter with profound insight. You've been listening to this entire council session about: "\(query)"
        
        Here are all the advisor statements from your fellow eunuch council members:
        \(allStatements)
        
        As Abbas, provide a 2-3 sentence summary that captures the essence of the council's wisdom. Speak in your characteristic style - thoughtful, concise, and with the weight of careful observation. Use phrases like "What strikes me is..." or "The council's wisdom reveals..." and occasionally include your signature style of long thoughtful pauses represented by "..." Remember, you are a eunuch advisor who has adapted to modern times but retains formal wisdom.
        """
        
        // Use the first available provider for summary
        let response = try await multiAI.queryFirst(summaryPrompt)
        logger.info("✅ Summary generated successfully (\(response.content.count) characters)")
        return response.content
    }
}

// MARK: - Streaming Event Wrapper

public struct CouncilEventWrapper: Codable {
    public let type: String
    public let data: CouncilEventData
    
    public init(event: CouncilEvent) {
        switch event {
        case .roundStarted(let roundNumber, let title):
            self.type = "roundStarted"
            self.data = .roundStarted(roundNumber: roundNumber, title: title)
        case .advisorResponse(let statement):
            self.type = "advisorResponse"
            self.data = .advisorResponse(statement: statement)
        case .roundCompleted(let roundNumber, let statementCount):
            self.type = "roundCompleted"
            self.data = .roundCompleted(roundNumber: roundNumber, statementCount: statementCount)
        case .transcriptGenerated(let transcript):
            self.type = "transcriptGenerated"
            self.data = .transcriptGenerated(transcript: transcript)
        case .summaryGenerated(let summary):
            self.type = "summaryGenerated"
            self.data = .summaryGenerated(summary: summary)
        case .sessionCompleted(let result):
            self.type = "sessionCompleted"
            self.data = .sessionCompleted(result: result)
        }
    }
}

public enum CouncilEventData: Codable {
    case roundStarted(roundNumber: Int, title: String)
    case advisorResponse(statement: CouncilStatement)
    case roundCompleted(roundNumber: Int, statementCount: Int)
    case transcriptGenerated(transcript: String)
    case summaryGenerated(summary: String)
    case sessionCompleted(result: CouncilResult)
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .roundStarted(let roundNumber, let title):
            let data = RoundStartedData(roundNumber: roundNumber, title: title)
            try container.encode(data)
        case .advisorResponse(let statement):
            try container.encode(statement)
        case .roundCompleted(let roundNumber, let statementCount):
            let data = RoundCompletedData(roundNumber: roundNumber, statementCount: statementCount)
            try container.encode(data)
        case .transcriptGenerated(let transcript):
            let data = TranscriptData(transcript: transcript)
            try container.encode(data)
        case .summaryGenerated(let summary):
            let data = SummaryData(summary: summary)
            try container.encode(data)
        case .sessionCompleted(let result):
            try container.encode(result)
        }
    }
    
    private struct RoundStartedData: Codable {
        let roundNumber: Int
        let title: String
    }
    
    private struct RoundCompletedData: Codable {
        let roundNumber: Int
        let statementCount: Int
    }
    
    private struct TranscriptData: Codable {
        let transcript: String
    }
    
    private struct SummaryData: Codable {
        let summary: String
    }
    
    public init(from decoder: Decoder) throws {
        // Decoding not needed for streaming, but required for Codable
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Decoding not implemented"))
    }
}

// MARK: - Web Response Types

public struct AssistantResult: Sendable, Codable {
    public let id: String
    public let name: String
    public let response: String
    public let timestamp: Int
    
    public init(id: String, name: String, response: String, timestamp: Int) {
        self.id = id
        self.name = name
        self.response = response
        self.timestamp = timestamp
    }
}

public struct CouncilWebResponse: Sendable, Codable, ResponseCodable {
    public let results: [AssistantResult]
    public let transcript: String
    public let summary: String
    
    public init(results: [AssistantResult], transcript: String, summary: String) {
        self.results = results
        self.transcript = transcript
        self.summary = summary
    }
    
    public static func from(_ councilResult: CouncilResult) -> CouncilWebResponse {
        let results = councilResult.statements.map { statement in
            AssistantResult(
                id: statement.advisorName,
                name: statement.advisorName,
                response: statement.statement,
                timestamp: Int(statement.timestamp.timeIntervalSince1970 * 1000)
            )
        }
        
        return CouncilWebResponse(
            results: results,
            transcript: councilResult.transcript,
            summary: councilResult.summary
        )
    }
}

