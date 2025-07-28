//
//  ZoomButton.swift
//  Chalkak
//
//  Created by 정종문 on 7/25/25.
//

import SwiftUI

/// 현재 줌 배율을 표시하는 ZoomIndicator
struct ZoomButton: View {
    let text: String
    let isActive: Bool
    let width: CGFloat

    var body: some View {
        Text(text)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(isActive ? SnappieColor.labelPrimaryActive : SnappieColor.labelPrimaryNormal)
            .frame(width: width, height: 32)
            .background(
                LinearGradient(
                    gradient: SnappieColor.gradientFillNormal,
                    startPoint: UnitPoint(x: 0.03, y: 0.08),
                    endPoint: UnitPoint(x: 0.95, y: 0.96)
                )
                .frame(width: width, height: 32)
                .mask(RoundedRectangle(cornerRadius: 16))
            )
            .animation(.easeInOut(duration: 0.2), value: isActive)
            .animation(.easeInOut(duration: 0.2), value: width)
    }
}
