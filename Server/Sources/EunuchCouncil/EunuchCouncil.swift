import Foundation

#if os(Linux)
import FoundationNetworking
#endif
import Hummingbird

@main
struct EunuchCouncil {
    static func loadConfigurations() throws -> [AIConfiguration] {
        let secretsURL = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "secrets.json")
        
        let data = try Data(contentsOf: secretsURL)
        return try JSONDecoder().decode([AIConfiguration].self, from: data)
    }
    
    static func main() async throws {
        print("🤖 EunuchCouncil - Multi-AI Query System")
        print("==========================================")

        let webDir = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Web")
        print(webDir.path)

        let router = Router()
            .addMiddleware {
                RequestLoggerMiddleware()
                FileMiddleware(webDir.path, searchForIndexHtml: true)
                CORSMiddleware(
                    allowOrigin: .originBased,
                    allowHeaders: [.accept, .authorization, .contentType, .origin],
                    allowMethods: [.get, .post, .options]
                )
            }
        
        // Add CORS preflight for streaming endpoint
        router.on("/stream/council", method: .options) { _, _ in
            Response(status: .ok)
        }
        
        // Add streaming council endpoint
        router.get("/stream/council") { req, context in
            guard let query = req.uri.queryParameters.get("query") else {
                throw HTTPError(.badRequest, message: "Missing query parameter")
            }
            
            // Create coordinator
            let configurations = try loadConfigurations()
            let coordinator = MultiAICoordinator()
            
            for config in configurations {
                switch config.provider {
                case "openai":
                    coordinator.addAdapter(OpenAIAdapter(configuration: config))
                case "anthropic":
                    coordinator.addAdapter(AnthropicAdapter(configuration: config))
                case "gemini":
                    coordinator.addAdapter(GeminiAdapter(configuration: config))
                case "perplexity":
                    coordinator.addAdapter(PerplexityAdapter(configuration: config))
                case "mistral":
                    coordinator.addAdapter(MistralAdapter(configuration: config))
                default:
                    break
                }
            }
            
            let council = CouncilOrchestrator(multiAI: coordinator)
            let session = council.startCouncilSession(query: query)
            
            return Response(
                status: .ok,
                headers: [
                    .contentType: "text/event-stream",
                    .cacheControl: "no-cache",
                    .connection: "keep-alive",
                    .accessControlAllowOrigin: "*"
                ],
                body: .init(asyncSequence: session.map { event in
                    do {
                        let jsonData = try JSONEncoder().encode(CouncilEventWrapper(event: event))
                        let dataString = String(data: jsonData, encoding: .utf8) ?? "{}"
                        return ByteBuffer(string: "data: \(dataString)\n\n")
                    } catch {
                        return ByteBuffer(string: "data: {\"error\": \"encoding failed\"}\n\n")
                    }
                })
            )
        }
        
        // Add test endpoint
        router.get("/test") { _, _ in
            Response(status: .ok, body: .init { writer in
                try await writer.write(ByteBuffer(string: "Server is running!"))
            })
        }

        let apiRoutes = router.group("api")
        configure(router: apiRoutes)

        let app = Application(
            router: router,
            configuration: .init(address: .hostname("127.0.0.1", port: 8077))
        )
        try await app.runService()
    }

    struct QueryRequest: Decodable {
        let query: String
    }

    static func configure(router: some RouterMethods) {
        router.on("/query", method: .options) { _, _ in
            Response(status: .ok)
        }

        router.post("/query") { req, ctx in
            do {
                let queryRequest = try await req.decode(as: QueryRequest.self, context: ctx)
                
                // Load configurations and create coordinator
                let configurations = try loadConfigurations()
                let coordinator = MultiAICoordinator()
                
                // Add adapters
                for config in configurations {
                    switch config.provider {
                    case "openai":
                        coordinator.addAdapter(OpenAIAdapter(configuration: config))
                    case "anthropic":
                        coordinator.addAdapter(AnthropicAdapter(configuration: config))
                    case "gemini":
                        coordinator.addAdapter(GeminiAdapter(configuration: config))
                    case "perplexity":
                        coordinator.addAdapter(PerplexityAdapter(configuration: config))
                    case "mistral":
                        coordinator.addAdapter(MistralAdapter(configuration: config))
                    default:
                        print("⚠️ Unknown provider: \(config.provider)")
                    }
                }
                
                // Create council and conduct session
                let council = CouncilOrchestrator(multiAI: coordinator)
                let result = try await council.conductCouncilSession(query: queryRequest.query)
                
                // Convert to web response format
                return CouncilWebResponse.from(result)
                
            } catch {
                print("❌ Error processing query: \(error)")
                throw HTTPError(.internalServerError, message: "Council session failed")
            }
        }
    }

    static func demonstrateMultiAI() async {
        print("🏛️ DEMONSTRATING THE EUNUCH COUNCIL")
        print("════════════════════════════════════")
        
        do {
            let configurations = try loadConfigurations()
            let coordinator = MultiAICoordinator()
            
            // Add adapters to coordinator based on provider
            for config in configurations {
                switch config.provider {
                case "openai":
                    coordinator.addAdapter(OpenAIAdapter(configuration: config))
                case "anthropic":
                    coordinator.addAdapter(AnthropicAdapter(configuration: config))
                case "gemini":
                    coordinator.addAdapter(GeminiAdapter(configuration: config))
                case "perplexity":
                    coordinator.addAdapter(PerplexityAdapter(configuration: config))
                case "mistral":
                    coordinator.addAdapter(MistralAdapter(configuration: config))
                default:
                    print("⚠️ Unknown provider: \(config.provider)")
                }
            }

            print("Available AI providers: \(coordinator.listProviders().joined(separator: ", "))")
            print("\n🤝 Convening the Council of Eunuch Advisors...")
            
            let council = CouncilOrchestrator(multiAI: coordinator)
            let testQuery = "I spend 4+ hours a day on TikTok and I'm starting to think it's affecting my productivity. Should I delete the app?"
            
            print("\n📜 COUNCIL QUESTION: \(testQuery)")
            print(String(repeating: "═", count: 80))
            
            let result = try await council.conductCouncilSession(query: testQuery)
            
            // Print the full transcript
            print("\n" + result.transcript)
            
            print("\n" + String(repeating: "═", count: 80))
            print("📋 COUNCIL SUMMARY:")
            print(result.summary)
            
            print("\n🏁 Council session completed!")
            
        } catch {
            print("❌ Error during council demonstration: \(error)")
        }
    }
}
