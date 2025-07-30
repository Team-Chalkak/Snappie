//
//  ProjectTimeBoardView.swift
//  Chalkak
//
//  Created by 배현진 on 7/28/25.
//

import SwiftUI

struct ProjectTimeBoardView: View {
    let totalDuration: Double
    let playHeadPosition: Double
    let dragOffset: CGFloat
    let pxPerSecond: CGFloat
    let rulerHeight: CGFloat

    var body: some View {
        GeometryReader { geo in
            let halfWidth = geo.size.width / 2
            HStack(alignment: .center, spacing: 0) {
                ForEach(0...Int(totalDuration), id: \.self) { sec in
                    VStack(spacing: 2) {
                        if sec % 2 == 1 {
                            Text("\(sec)초")
                                .font(.caption2)
                        } else {
                            Circle().frame(width: 5, height: 5)
                        }
                    }
                    .frame(width: pxPerSecond, height: rulerHeight)
                    .foregroundStyle(SnappieColor.darkLight)
                }
            }
            .padding(.horizontal, halfWidth)
            .offset(x: -CGFloat(playHeadPosition) * pxPerSecond + dragOffset)
            .frame(
                width: geo.size.width + CGFloat(totalDuration) * pxPerSecond,
                height: rulerHeight,
                alignment: .leading
            )
        }
        .frame(height: rulerHeight)
    }
}
