//
//  OnboardingEditorTooltip.swift
//  Chalkak
//
//  Created by 배현진 on 6/28/26.
//

import SwiftUI

struct OnboardingEditorTooltip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(SnappieColor.labelDarkNormal)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(SnappieColor.tooltipBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                TooltipTriangleShape()
                    .fill(SnappieColor.primaryNormal)
                    .frame(width: 14, height: 10)
                    .offset(x: 18, y: 9)
            }
    }
}
