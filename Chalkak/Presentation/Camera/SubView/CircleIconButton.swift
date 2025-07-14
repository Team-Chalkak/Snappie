//
//  CircleIconButton.swift
//  CameraProject
//
//  Created by 정종문 on 7/14/25.
//
import SwiftUI

struct CircleIconButton: View {
    let iconName: String
    let action: () -> Void
    var iconSize: (width: CGFloat, height: CGFloat) = (30, 30)
    var buttonSize: CGFloat = 48
    var isSelected: Bool = false

    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize.width, height: iconSize.height)
                .foregroundColor(isSelected ? .blue : .white)
                .frame(width: buttonSize, height: buttonSize)
        }
        .frame(width: buttonSize, height: buttonSize)
        .background(Color.black.opacity(0.6))
        .clipShape(Circle())
    }
}
