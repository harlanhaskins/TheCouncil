//
//  SummaryView.swift
//  EunuchCouncil
//
//  Created by Harlan Haskins on 7/27/25.
//

import SwiftUI

struct SummaryView: View {
    let summary: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Abbas speaks:")
                .font(.title3.weight(.semibold))
                .fontWeight(.semibold)
                .foregroundColor(.eunuchGold)
            
            Text(summary)
                .font(.body)
                .foregroundColor(.eunuchGoldLight)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .italic()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.eunuchBrownMedium, Color.eunuchBrownDark]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.eunuchGold, lineWidth: 2)
                )
                .shadow(color: .eunuchGold.opacity(0.2), radius: 25)
                .shadow(color: .black.opacity(0.8), radius: 32, x: 0, y: 8)
        )
        .frame(maxWidth: .infinity)
        .fontDesign(.serif)
    }
}

#Preview {
    SummaryView(
        summary: "The council has reached a consensus. After careful deliberation, we recommend a measured approach that balances the immediate needs with long-term strategic considerations. The path forward requires both wisdom and decisive action."
    )
    .padding()
}
