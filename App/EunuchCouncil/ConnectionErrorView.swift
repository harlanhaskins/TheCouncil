//
//  ConnectionErrorView.swift
//  EunuchCouncil
//
//  Created by Harlan Haskins on 7/27/25.
//

import SwiftUI

struct ConnectionErrorView: View {
    let error: String
    
    var body: some View {
        HStack {
            Text("⚠️ Connection Error:")
                .fontWeight(.semibold)
            Text(error)
        }
        .font(.body)
        .foregroundColor(.red)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.red.opacity(0.5), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .fontDesign(.serif)
    }
}

#Preview {
    ConnectionErrorView(error: "Failed to connect to server. Please check your network connection.")
        .background(.eunuchBrown)
        .padding()
}