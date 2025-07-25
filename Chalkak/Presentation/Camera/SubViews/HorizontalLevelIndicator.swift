//
//  HorizontalLevelIndicator.swift
//  Chalkak
//
//  Created by Finn on 7/24/25.
//

import SwiftUI

struct HorizontalLevelIndicatorView: View {
    let gravityX: Double

    // 수평 여부 판정값 (-0.05~0.05사이면 수평)
    private var isLevel: Bool {
        abs(gravityX) < 0.05
    }

    // 기울기 각도
    private var tiltAngle: Double {
        let maxAngle = 30.0 // 최대 표시 각도
        let clampedGravity = max(-0.5, min(0.5, gravityX))
        return clampedGravity * maxAngle * 2
    }

    // 선 색상
    private var lineColor: Color {
        isLevel ? SnappieColor.labelPrimaryActive : SnappieColor.labelPrimaryNormal
    }

    var body: some View {
        HStack(spacing: 0) {
            levelLine(fixedWidth: 20, tiltedWidth: 48, isReversed: false)
            Spacer().frame(width: 25)
            levelLine(fixedWidth: 20, tiltedWidth: 48, isReversed: true)
        }
        .frame(height: 50)
        .animation(.easeInOut(duration: 0.1), value: tiltAngle)
        .animation(.easeInOut(duration: 0.2), value: lineColor)
    }

    private func levelLine(fixedWidth: CGFloat, tiltedWidth: CGFloat, isReversed: Bool) -> some View {
        HStack(spacing: 0) {
            if !isReversed {
                fixedLine(width: fixedWidth)
                tiltedLine(width: tiltedWidth)
            } else {
                tiltedLine(width: tiltedWidth)
                fixedLine(width: fixedWidth)
            }
        }
    }

    /// 고정선(양끝 20px)
    private func fixedLine(width: CGFloat) -> some View {
        Rectangle()
            .frame(width: width, height: 1)
            .foregroundColor(lineColor)
    }

    /// 유동선 (가운데 48px)
    private func tiltedLine(width: CGFloat) -> some View {
        Rectangle()
            .frame(width: width, height: 1)
            .foregroundColor(lineColor)
            .rotationEffect(.degrees(tiltAngle), anchor: .center)
    }
}
