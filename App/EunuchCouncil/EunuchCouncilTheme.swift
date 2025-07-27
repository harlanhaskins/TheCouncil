//
//  EunuchCouncilTheme.swift
//  EunuchCouncil
//
//  Created by Harlan Haskins on 7/27/25.
//

import SwiftUI

// MARK: - Color Extensions

extension ShapeStyle where Self == Color {
    static var eunuchBrown: Color { Color(red: 15/255, green: 7/255, blue: 2/255) }
    static var eunuchBrownMedium: Color { Color(red: 43/255, green: 26/255, blue: 15/255) }
    static var eunuchBrownDark: Color { Color(red: 43/255, green: 24/255, blue: 16/255) }
    static var eunuchGold: Color { Color(red: 212/255, green: 175/255, blue: 55/255) }
    static var eunuchGoldDark: Color { Color(red: 139/255, green: 105/255, blue: 20/255) }
    static var eunuchGoldLight: Color { Color(red: 212/255, green: 184/255, blue: 150/255) }
}

// MARK: - Text Field Style

struct EunuchTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.body)
            .foregroundColor(.eunuchGoldLight)
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 26/255, green: 15/255, blue: 10/255))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.eunuchGoldDark, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 0)
                    .shadow(color: .eunuchGold.opacity(0.1), radius: 10, x: 0, y: 0)
            )
    }
}

