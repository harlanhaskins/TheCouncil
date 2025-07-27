//
//  ContentView.swift
//  EunuchCouncil
//
//  Created by Harlan Haskins on 7/27/25.
//

import SwiftUI
import EunuchCouncil

struct ContentView: View {
    @State private var query = ""
    @State private var navigationPath = NavigationPath()
    @State private var viewModel = CouncilViewModel()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 12) {
                Spacer()

                // Council title and description
                VStack(spacing: 20) {
                    Text("The Eunuch Council")
                        .font(.largeTitle.weight(.semibold))
                        .fontWeight(.bold)
                        .foregroundColor(.eunuchGold)
                        .multilineTextAlignment(.center)

                    Text("Convene the council of wise advisors to seek guidance on your most pressing questions.")
                        .font(.body)
                        .foregroundColor(.eunuchGoldLight)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Query input form
                VStack(spacing: 20) {
                    TextField("Enter your question here...", text: $query, axis: .vertical)
                        .lineLimit(3...6)
                        .textFieldStyle(EunuchTextFieldStyle())

                    Button(action: {
                        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            navigationPath.append("council")
                        }
                    }) {
                        Text("Convene Council")
                            .font(.title3.weight(.semibold))
                            .fontWeight(.semibold)
                            .foregroundColor(.eunuchBrownDark)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.eunuchGoldDark, .eunuchGold]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.eunuchGold, lineWidth: 2)
                            )
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
                    }
                    .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.eunuchBrownMedium)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.eunuchGoldDark, lineWidth: 2)
                        )
                        .shadow(color: .eunuchGold.opacity(0.1), radius: 40)
                        .shadow(color: .black.opacity(0.8), radius: 40, x: 0, y: 12)
                )
                .padding(.horizontal, 12)

                Spacer()
            }
            .fontDesign(.serif)
            .navigationBarHidden(true)
            .navigationDestination(for: String.self) { destination in
                if destination == "council" {
                    CouncilResultsView(viewModel: viewModel, query: query)
                }
            }
        }
        .background {
            ZStack {
                // Dark brown background with subtle gradients
                Color.eunuchBrown

                // Subtle radial gradients for texture
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.eunuchGold.opacity(0.1),
                        Color.clear
                    ]),
                    center: UnitPoint(x: 0.2, y: 0.2),
                    startRadius: 0,
                    endRadius: 300
                )

                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.eunuchGold.opacity(0.08),
                        Color.clear
                    ]),
                    center: UnitPoint(x: 0.8, y: 0.3),
                    startRadius: 0,
                    endRadius: 250
                )
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    ContentView()
}
