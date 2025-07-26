import Foundation

public class MultiAICoordinator {
    private var adapters: [AIAdapter] = []
    
    public init() {}
    
    public func addAdapter(_ adapter: AIAdapter) {
        adapters.append(adapter)
    }
    
    public func removeAdapter(providerName: String) {
        adapters.removeAll { $0.providerName == providerName }
    }
    
    public func queryAll(_ prompt: String) async -> [String: Result<AIResponse, AIError>] {
        return await withTaskGroup(of: (String, Result<AIResponse, AIError>).self) { group in
            for adapter in adapters {
                group.addTask {
                    let result: Result<AIResponse, AIError>
                    do {
                        let response = try await adapter.sendPrompt(prompt)
                        result = .success(response)
                    } catch let error as AIError {
                        result = .failure(error)
                    } catch {
                        result = .failure(.networkError(error))
                    }
                    return (adapter.providerName, result)
                }
            }
            
            var results: [String: Result<AIResponse, AIError>] = [:]
            for await (providerName, result) in group {
                results[providerName] = result
            }
            return results
        }
    }
    
    public func querySequential(_ prompt: String) async -> [String: Result<AIResponse, AIError>] {
        var results: [String: Result<AIResponse, AIError>] = [:]
        
        for adapter in adapters {
            let result: Result<AIResponse, AIError>
            do {
                let response = try await adapter.sendPrompt(prompt)
                result = .success(response)
            } catch let error as AIError {
                result = .failure(error)
            } catch {
                result = .failure(.networkError(error))
            }
            results[adapter.providerName] = result
        }
        
        return results
    }
    
    public func queryFirst(_ prompt: String) async throws -> AIResponse {
        guard !adapters.isEmpty else {
            throw AIError.invalidConfiguration
        }
        
        let adapter = adapters.first!
        return try await adapter.sendPrompt(prompt)
    }
    
    public func queryRace(_ prompt: String) async throws -> AIResponse {
        guard !adapters.isEmpty else {
            throw AIError.invalidConfiguration
        }
        
        return try await withThrowingTaskGroup(of: AIResponse.self) { group in
            for adapter in adapters {
                group.addTask {
                    try await adapter.sendPrompt(prompt)
                }
            }
            
            guard let result = try await group.next() else {
                throw AIError.invalidConfiguration
            }
            
            group.cancelAll()
            return result
        }
    }
    
    public func listProviders() -> [String] {
        return adapters.map { $0.providerName }
    }
    
    public func querySpecificProvider(_ providerName: String, prompt: String) async throws -> AIResponse {
        guard let adapter = adapters.first(where: { $0.providerName == providerName }) else {
            throw AIError.invalidConfiguration
        }
        
        return try await adapter.sendPrompt(prompt)
    }
}
