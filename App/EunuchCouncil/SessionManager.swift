//
//  SessionManager.swift
//  EunuchCouncil
//
//  Created by Harlan Haskins on 7/27/25.
//

import Foundation
import EunuchCouncil

@MainActor
struct CouncilSession: Identifiable {
    let id: UUID
    let query: String
    let viewModel: CouncilViewModel
    let createdAt: Date
    
    var isActive: Bool {
        viewModel.isLoading || !viewModel.councilState.isComplete
    }
    
    var isCompleted: Bool {
        viewModel.councilState.isComplete
    }
    
    init(query: String) {
        self.id = UUID()
        self.query = query
        self.viewModel = CouncilViewModel()
        self.createdAt = Date()
    }
}

@MainActor
@Observable
class SessionManager {
    static let shared = SessionManager()
    
    var sessions: [CouncilSession] = []
    
    private init() {}
    
    func createSession(query: String) -> CouncilSession {
        let session = CouncilSession(query: query)
        sessions.insert(session, at: 0) // Most recent first
        
        // Start the session
        session.viewModel.conveneCouncil(query: query)
        
        // Observe completion to save to history
        Task {
            await observeSessionCompletion(session)
        }
        
        return session
    }
    
    func getSession(id: UUID) -> CouncilSession? {
        return sessions.first { $0.id == id }
    }
    
    func removeSession(_ session: CouncilSession) {
        session.viewModel.cancelSession()
        sessions.removeAll { $0.id == session.id }
    }
    
    var activeSessions: [CouncilSession] {
        sessions.filter { $0.isActive }
    }
    
    var completedSessions: [CouncilSession] {
        sessions.filter { $0.isCompleted }
    }
    
    private func observeSessionCompletion(_ session: CouncilSession) async {
        // Poll until session is complete
        while !session.viewModel.councilState.isComplete {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        // Save to persistent history when complete
        SessionHistoryManager.shared.saveSession(
            query: session.query,
            councilState: session.viewModel.councilState
        )
        
        // Remove from active sessions list
        sessions.removeAll { $0.id == session.id }
    }
}
