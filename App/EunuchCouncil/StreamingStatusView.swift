//
//  StreamingStatusView.swift
//  EunuchCouncil
//
//  Created by Harlan Haskins on 7/27/25.
//

import SwiftUI
import EunuchCouncil

struct StreamingStatusView: View {
    let councilState: CouncilState
    
    var body: some View {
        VStack(spacing: 8) {
            if let round = councilState.currentRound {
                Text("🏛️ Round \(round): \(councilState.roundTitle)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.eunuchGold)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            
            Text("\(councilState.results.count) advisors have spoken")
                .font(.body)
                .foregroundColor(.eunuchGoldLight)
        }
        .fontDesign(.serif)
    }
}

#Preview {
    StreamingStatusView(
        councilState: CouncilState(
            results: [
                AssistantResult(
                    id: "Zafir",
                    name: "Zafir",
                    response: "Sample response",
                    timestamp: Int(Date().timeIntervalSince1970 * 1000),
                    uuid: UUID().uuidString,
                    provider: .anthropic
                )
            ],
            currentRound: 1,
            roundTitle: "Initial Deliberations"
        )
    )
    .padding()
}
