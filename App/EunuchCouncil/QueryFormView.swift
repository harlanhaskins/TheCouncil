//
//  QueryFormView.swift
//  EunuchCouncil
//
//  Created by Harlan Haskins on 7/27/25.
//

import SwiftUI
import EunuchCouncil

struct QueryFormView: View {
    @Binding var query: String
    let isLoading: Bool
    let councilState: CouncilState
    let onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                TextField("Enter your question here...", text: $query, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(EunuchTextFieldStyle())
                
                Button(action: onSubmit) {
                    Text(isLoading ? "Convening..." : "Convene")
                        .font(.title3.weight(.semibold))
                        .fontWeight(.semibold)
                        .foregroundColor(.eunuchBrownDark)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.eunuchGoldDark, .eunuchGold]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.eunuchGold, lineWidth: 2)
                        )
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                .opacity((query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading) ? 0.6 : 1.0)
            }
            
            // Inline streaming status (only when no summary available)
            if isLoading && councilState.currentRound != nil && councilState.summary.isEmpty {
                StreamingStatusView(councilState: councilState)
                    .padding(.top, 8)
            }
        }
        .padding(12)
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
        .frame(maxWidth: councilState.summary.isEmpty ? .infinity : 500)
        .fontDesign(.serif)
    }
}

#Preview {
    QueryFormView(
        query: .constant("What should we do about the economy?"),
        isLoading: true,
        councilState: CouncilState(
            currentRound: 1,
            roundTitle: "Initial Deliberations"
        ),
        onSubmit: {}
    )
    .padding()
}
