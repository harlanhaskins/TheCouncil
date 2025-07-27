//
//  CouncilResultsView.swift
//  EunuchCouncil
//
//  Created by Harlan Haskins on 7/27/25.
//

import SwiftUI
import EunuchCouncil

struct CouncilResultsView: View {
    var viewModel: CouncilViewModel
    @State private var showTranscriptPopover = false
    let query: String

    var body: some View {
        // Main scrollable content
        ZStack {
            if !viewModel.councilState.results.isEmpty {
                AdvisorGridView(
                    councilState: viewModel.councilState,
                    isLoading: viewModel.isLoading
                )
            } else if viewModel.isLoading {
                // Show loading state when no results yet
                VStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                        .tint(.eunuchGold)

                    Text("The council is convening...")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.eunuchGold)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 12) {
                // Fixed-size header that switches between status and summary
                Group {
                    if !viewModel.councilState.summary.isEmpty {
                        // Show summary when available
                        SummaryView(summary: viewModel.councilState.summary)
                    } else {
                        // Show streaming status when no summary
                        VStack(spacing: 12) {
                            // Original question
                            Text("\"\(query)\"")
                                .font(.body)
                                .foregroundColor(.eunuchGoldLight)
                                .italic()
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 10)

                            if let round = viewModel.councilState.currentRound {
                                Text("🏛️ Round \(round): \(viewModel.councilState.roundTitle)")
                                    .font(.title3.weight(.semibold))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.eunuchGold)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }

                            Text("\(viewModel.councilState.results.count) advisors have spoken")
                                .font(.body)
                                .foregroundColor(.eunuchGoldLight)
                        }
                        .padding(30)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.eunuchBrownMedium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.eunuchGoldDark, lineWidth: 2)
                                )
                                .shadow(color: .eunuchGold.opacity(0.1), radius: 30)
                                .shadow(color: .black.opacity(0.8), radius: 32, x: 0, y: 8)
                        )
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: !viewModel.councilState.summary.isEmpty)
                .padding(.horizontal, 20)

                // Connection error
                if let error = viewModel.connectionError {
                    ConnectionErrorView(error: error)
                }
            }
            .padding(.top)
        }
        .fontDesign(.serif)
        .navigationTitle("Council Deliberations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.councilState.transcript.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Transcript") {
                        showTranscriptPopover = true
                    }
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundColor(.eunuchGold)
                    .popover(isPresented: $showTranscriptPopover) {
                        TranscriptPopoverView(transcript: viewModel.councilState.transcript)
                    }
                }
            }
        }
        .onAppear {
            // Start the council session when the view appears
            if viewModel.councilState.results.isEmpty && !viewModel.isLoading {
                viewModel.conveneCouncil(query: query)
            }
        }
        .onDisappear {
            viewModel.cancelSession()
        }
    }
}

#Preview {
    NavigationStack {
        CouncilResultsView(
            viewModel: CouncilViewModel(),
            query: "What should we do about the economy?"
        )
    }
}
