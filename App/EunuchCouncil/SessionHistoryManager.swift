//
//  SessionHistoryManager.swift
//  EunuchCouncil
//
//  Created by Harlan Haskins on 7/27/25.
//

import Foundation
import EunuchCouncil

struct SessionHistory: Codable, Identifiable {
    let id: UUID
    let query: String
    let councilState: CouncilState
    let date: Date
    
    init(query: String, councilState: CouncilState) {
        self.id = UUID()
        self.query = query
        self.councilState = councilState
        self.date = Date()
    }
}

@MainActor
class SessionHistoryManager: ObservableObject {
    static let shared = SessionHistoryManager()
    
    @Published var sessions: [SessionHistory] = []
    
    private init() {
        loadSessions()
    }
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var historyDirectory: URL {
        documentsDirectory.appendingPathComponent("CouncilHistory")
    }
    
    func saveSession(query: String, councilState: CouncilState) {
        let session = SessionHistory(query: query, councilState: councilState)
        sessions.insert(session, at: 0) // Most recent first
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: historyDirectory, withIntermediateDirectories: true)
        
        // Save to individual JSON file
        let fileURL = historyDirectory.appendingPathComponent("\(session.id.uuidString).json")
        do {
            let data = try JSONEncoder().encode(session)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save session: \(error)")
        }
    }
    
    func deleteSession(_ session: SessionHistory) {
        sessions.removeAll { $0.id == session.id }
        
        let fileURL = historyDirectory.appendingPathComponent("\(session.id.uuidString).json")
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    private func loadSessions() {
        guard let urls = try? FileManager.default.contentsOfDirectory(at: historyDirectory, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }
        
        var loadedSessions: [SessionHistory] = []
        
        for url in urls where url.pathExtension == "json" {
            do {
                let data = try Data(contentsOf: url)
                let session = try JSONDecoder().decode(SessionHistory.self, from: data)
                loadedSessions.append(session)
            } catch {
                print("Failed to load session from \(url): \(error)")
            }
        }
        
        // Sort by date, most recent first
        sessions = loadedSessions.sorted { $0.date > $1.date }
    }
}