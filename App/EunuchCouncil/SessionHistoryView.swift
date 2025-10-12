//
//  SessionHistoryView.swift
//  EunuchCouncil
//
//  Created by Harlan Haskins on 7/27/25.
//

import SwiftUI
import EunuchCouncil

struct SessionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var historyManager = SessionHistoryManager.shared
    @State private var sessionManager = SessionManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.eunuchBrown.ignoresSafeArea()
                
                if sessionManager.sessions.isEmpty && historyManager.sessions.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "clock")
                            .font(.system(size: 60))
                            .foregroundColor(.eunuchGold.opacity(0.6))
                        
                        Text("No Previous Sessions")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.eunuchGold)
                        
                        Text("Your council deliberations will appear here after completion.")
                            .font(.body)
                            .foregroundColor(.eunuchGoldLight)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Active sessions section
                            if !sessionManager.sessions.isEmpty {
                                Section {
                                    ForEach(sessionManager.sessions) { session in
                                        ActiveSessionCard(session: session)
                                            .contextMenu {
                                                Button("Cancel Session", role: .destructive) {
                                                    withAnimation {
                                                        sessionManager.removeSession(session)
                                                    }
                                                }
                                            }
                                    }
                                } header: {
                                    HStack {
                                        Text("Active Sessions")
                                            .font(.title2.weight(.semibold))
                                            .foregroundColor(.eunuchGold)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                }
                            }
                            
                            // Completed sessions section
                            if !historyManager.sessions.isEmpty {
                                Section {
                                    ForEach(historyManager.sessions) { session in
                                        SessionHistoryCard(session: session)
                                            .contextMenu {
                                                Button("Delete Session", role: .destructive) {
                                                    withAnimation {
                                                        historyManager.deleteSession(session)
                                                    }
                                                }
                                            }
                                    }
                                } header: {
                                    HStack {
                                        Text("Completed Sessions")
                                            .font(.title2.weight(.semibold))
                                            .foregroundColor(.eunuchGold)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, sessionManager.sessions.isEmpty ? 8 : 24)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .animation(.spring, value: sessionManager.sessions.count)
            .navigationTitle("Council History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundColor(.eunuchGold)
                }
            }
            .navigationDestination(for: UUID.self) { sessionId in
                if let session = sessionManager.getSession(id: sessionId) {
                    CouncilResultsView(session: session)
                }
            }
        }
        .fontDesign(.serif)
    }
}

struct ActiveSessionCard: View {
    let session: CouncilSession
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        NavigationLink(value: session.id) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.query)
                            .font(.body.weight(.semibold))
                            .foregroundColor(.eunuchGold)
                            .lineLimit(2)
                        
                        HStack {
                            Text(dateFormatter.string(from: session.createdAt))
                                .font(.caption)
                                .foregroundColor(.eunuchGoldLight)
                            
                            if session.viewModel.isLoading {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(session.viewModel.isLoading ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: session.viewModel.isLoading)
                                
                                Text("Active")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else if session.viewModel.councilState.isComplete {
                                Circle()
                                    .fill(Color.eunuchGold)
                                    .frame(width: 8, height: 8)
                                
                                Text("Complete")
                                    .font(.caption)
                                    .foregroundColor(.eunuchGold)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(session.viewModel.councilState.results.count)")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.eunuchGold)
                        
                        Text("advisors")
                            .font(.caption)
                            .foregroundColor(.eunuchGoldLight)
                    }
                }
                
                if !session.viewModel.councilState.summary.isEmpty {
                    Text(session.viewModel.councilState.summary)
                        .font(.caption)
                        .foregroundColor(.eunuchGoldLight)
                        .lineLimit(3)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.eunuchBrownMedium)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(session.viewModel.isLoading ? Color.green : Color.eunuchGoldDark, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SessionHistoryCard: View {
    let session: SessionHistory
    @State private var showingDetail = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.query)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.eunuchGold)
                        .lineLimit(2)
                    
                    Text(dateFormatter.string(from: session.date))
                        .font(.caption)
                        .foregroundColor(.eunuchGoldLight)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(session.councilState.results.count)")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.eunuchGold)
                    
                    Text("advisors")
                        .font(.caption)
                        .foregroundColor(.eunuchGoldLight)
                }
            }
            
            if !session.councilState.summary.isEmpty {
                Text(session.councilState.summary)
                    .font(.caption)
                    .foregroundColor(.eunuchGoldLight)
                    .lineLimit(3)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.eunuchBrownMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.eunuchGoldDark, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 2)
        )
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            SessionDetailView(session: session)
        }
    }
}

struct SessionDetailView: View {
    let session: SessionHistory
    @Environment(\.dismiss) private var dismiss
    @State private var showTranscriptPopover = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .medium
        return formatter
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.eunuchBrown.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if !session.councilState.summary.isEmpty {
                        SummaryView(summary: session.councilState.summary)
                            .padding(.horizontal, 20)
                            .padding(.top)
                    }
                    
                    AdvisorGridView(
                        councilState: session.councilState,
                        isLoading: false
                    )
                }
            }
            .navigationTitle("Session Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundColor(.eunuchGold)
                }
                
                if !session.councilState.transcript.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Transcript") {
                            showTranscriptPopover = true
                        }
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundColor(.eunuchGold)
                        .popover(isPresented: $showTranscriptPopover) {
                            TranscriptPopoverView(transcript: session.councilState.transcript)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 8) {
                    Text("\"\(session.query)\"")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.eunuchGold)
                        .italic()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Text(dateFormatter.string(from: session.date))
                        .font(.caption)
                        .foregroundColor(.eunuchGoldLight)
                }
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.eunuchBrownMedium)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.eunuchGoldDark, lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .fontDesign(.serif)
    }
}

#Preview {
    SessionHistoryView()
}
