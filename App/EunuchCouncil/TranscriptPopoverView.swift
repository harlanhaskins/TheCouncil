//
//  TranscriptPopoverView.swift
//  EunuchCouncil
//
//  Created by Harlan Haskins on 7/27/25.
//

import SwiftUI

struct TranscriptPopoverView: View {
    let transcript: String
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if transcript.isEmpty {
                    VStack {
                        Spacer()
                        Text("Transcript will appear when ready...")
                            .font(.body)
                            .foregroundColor(.eunuchGoldLight.opacity(0.6))
                            .italic()
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                } else {
                    Text(transcript)
                        .font(.body)
                        .foregroundColor(.eunuchGoldLight)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .background(.eunuchBrown)
            .navigationTitle("Council Transcript")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationCompactAdaptation(.popover)
        .fontDesign(.serif)
    }
}
