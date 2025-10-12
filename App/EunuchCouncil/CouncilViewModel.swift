//
//  CouncilViewModel.swift
//  EunuchCouncil
//
//  Created by Harlan Haskins on 7/27/25.
//

import SwiftUI
import Combine
import Foundation
import EunuchCouncil

@Observable
@MainActor
class CouncilViewModel {
    var councilState = CouncilState()
    var isLoading = false
    var connectionError: String?

    @ObservationIgnored
    private var streamTask: Task<Void, Never>?
    
    func conveneCouncil(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Reset state
        councilState = CouncilState()
        isLoading = true
        connectionError = nil
        
        // Cancel existing stream
        streamTask?.cancel()
        
        // Start new stream
        streamTask = Task {
            await streamCouncilSession(query: query)
        }
    }
    
    private func streamCouncilSession(query: String) async {
        guard let url = URL(string: "https://council.harlanhaskins.com/stream/council") else {
            connectionError = "Invalid URL"
            isLoading = false
            return
        }

        // Create POST request with JSON body
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ["query": query]
        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            connectionError = "Failed to encode request"
            isLoading = false
            return
        }
        request.httpBody = jsonData

        do {
            let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                connectionError = "Server error"
                isLoading = false
                return
            }
            
            for try await line in asyncBytes.lines {
                if Task.isCancelled { break }
                
                // Server-Sent Events format: "data: {json}"
                if line.hasPrefix("data: ") {
                    let jsonString = String(line.dropFirst(6))
                    if let data = jsonString.data(using: .utf8) {
                        do {
                            let streamEvent = try JSONDecoder().decode(StreamEvent.self, from: data)
                            await handleStreamEvent(streamEvent.eventData)
                        } catch {
                            print("Failed to decode stream event: \(error)")
                        }
                    }
                }
            }
        } catch {
            if !Task.isCancelled {
                connectionError = "Connection failed: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func handleStreamEvent(_ eventData: StreamEventData) async {
        switch eventData {
        case .roundStarted(let roundNumber, let title):
            councilState = CouncilState(
                results: councilState.results,
                transcript: councilState.transcript,
                summary: councilState.summary,
                currentRound: roundNumber,
                roundTitle: title,
                isComplete: false
            )
            
        case .advisorResponse(let advisorName, let statement, let provider):
            let newResult = AssistantResult(
                id: advisorName,
                name: advisorName,
                response: statement,
                timestamp: Int(Date().timeIntervalSince1970 * 1000),
                uuid: UUID().uuidString,
                provider: provider
            )
            
            var updatedResults = councilState.results
            updatedResults.append(newResult)
            
            councilState = CouncilState(
                results: updatedResults,
                transcript: councilState.transcript,
                summary: councilState.summary,
                currentRound: councilState.currentRound,
                roundTitle: councilState.roundTitle,
                isComplete: false
            )
            
        case .roundCompleted:
            break // Just a marker, no state change needed
            
        case .transcriptGenerated(let transcript):
            councilState = CouncilState(
                results: councilState.results,
                transcript: transcript,
                summary: councilState.summary,
                currentRound: councilState.currentRound,
                roundTitle: councilState.roundTitle,
                isComplete: false
            )
            
        case .summaryGenerated(let summary):
            councilState = CouncilState(
                results: councilState.results,
                transcript: councilState.transcript,
                summary: summary,
                currentRound: councilState.currentRound,
                roundTitle: councilState.roundTitle,
                isComplete: false
            )
            
        case .sessionCompleted:
            councilState = CouncilState(
                results: councilState.results,
                transcript: councilState.transcript,
                summary: councilState.summary,
                currentRound: councilState.currentRound,
                roundTitle: councilState.roundTitle,
                isComplete: true
            )
            isLoading = false
        }
    }
    
    func cancelSession() {
        streamTask?.cancel()
        isLoading = false
    }
    
    deinit {
        streamTask?.cancel()
    }
}
