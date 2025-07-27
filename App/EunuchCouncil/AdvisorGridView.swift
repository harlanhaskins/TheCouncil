//
//  AdvisorGridView.swift
//  EunuchCouncil
//
//  Created by Harlan Haskins on 7/27/25.
//

import SwiftUI
import EunuchCouncil

struct AdvisorGridView: View {
    let councilState: CouncilState
    let isLoading: Bool
    
    private let advisors = EunuchCouncilConstants.advisors
    
    var body: some View {
        GeometryReader { geometry in
            let padding: CGFloat = 20
            let spacing: CGFloat = 16
            let availableWidth = geometry.size.width - (padding * 2)
            
            // Calculate optimal number of columns based on screen width
            let minCardWidth: CGFloat = 280
            let maxColumns = max(1, Int(availableWidth / minCardWidth))
            let columns = min(maxColumns, 4) // Cap at 4 columns for larger screens
            
            // Calculate card dimensions
            let cardWidth = (availableWidth - (spacing * CGFloat(columns - 1))) / CGFloat(columns)
            let cardHeight: CGFloat = 200 // Fixed height for consistency
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(cardWidth), spacing: spacing), count: columns), spacing: spacing) {
                    ForEach(advisors, id: \.name) { advisor in
                        AdvisorCardView(
                            advisor: advisor,
                            result: councilState.results.first { $0.name == advisor.name }
                        )
                        .frame(width: cardWidth, height: cardHeight)
                    }
                }
                .padding(padding)
            }
        }
        .fontDesign(.serif)
    }
}

struct AdvisorCardView: View {
    let advisor: Advisor
    let result: AssistantResult?
    
    private var hasSpoken: Bool {
        result != nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Fixed Header with name, timestamp, and favicon
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(advisor.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.eunuchGold)
                        .lineLimit(1)
                    
                    if let result = result {
                        Text(formatTimestamp(result.timestamp))
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.eunuchGoldLight.opacity(0.6))
                            .italic()
                    }
                    
                    Spacer()
                    
                    if let result = result {
                        AsyncImage(url: URL(string: result.provider.faviconURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Rectangle()
                                .fill(.clear)
                        }
                        .frame(width: 18, height: 18)
                        .opacity(0.7)
                    }
                }
                
                Divider()
                    .background(hasSpoken ? Color.eunuchGold : Color.eunuchGoldDark)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Scrollable Content
            if let result = result {
                ScrollView {
                    Text(result.response)
                        .font(.body)
                        .foregroundColor(.eunuchGoldLight)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack {
                    Spacer()
                    Text("Awaiting counsel...")
                        .font(.caption)
                        .foregroundColor(.eunuchGoldLight.opacity(0.6))
                        .italic()
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 26/255, green: 15/255, blue: 10/255),
                        Color.eunuchBrownMedium
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(hasSpoken ? .eunuchGold : .eunuchGoldDark, lineWidth: 2)
                )
                .shadow(
                    color: hasSpoken ? .eunuchGold.opacity(0.2) : .clear,
                    radius: hasSpoken ? 20 : 0
                )
                .shadow(color: .black.opacity(0.6), radius: 16, x: 0, y: 4)
        )
        .opacity(hasSpoken ? 1.0 : 0.7)
        .scaleEffect(hasSpoken ? 1.0 : 0.98)
        .animation(.easeOut(duration: 0.5), value: hasSpoken)
    }
    
    private func formatTimestamp(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    AdvisorGridView(
        councilState: CouncilState(
            results: [
                AssistantResult(
                    id: "Zafir",
                    name: "Zafir",
                    response: "The path forward requires both cunning and patience. We must consider the hidden motivations of all parties involved.",
                    timestamp: Int(Date().timeIntervalSince1970 * 1000),
                    uuid: UUID().uuidString,
                    provider: .anthropic
                )
            ]
        ),
        isLoading: true
    )
    .background(Color.eunuchBrown)
}
