//
//  TrimmingLineSliderView.swift
//  Chalkak
//
//  Created by 배현진 on 7/24/25.
//

import SwiftUI

struct TrimminglineSliderView: View {
    @Binding var clips: [EditableClip]
    @Binding var playHeadPosition: Double
    @Binding var isDragging: Bool
    let isPlaying: Bool
    let totalDuration: Double

    let onSeek: (Double) -> Void
    let onToggleTrimming: (String) -> Void
    let onTrimChanged: (String, Double, Double) -> Void

//    @State private var scrollOffset: CGFloat = 0

    private let pxPerSecond: CGFloat = 50
    private let clipSpacing: CGFloat = 8
    private let timelineHeight: CGFloat = 60


    var body: some View {
        GeometryReader { geo in
            let halfW = geo.size.width / 2

            ZStack(alignment: .leading) {
                // → HStack 을 패딩 후 offset 으로 좌측으로 밀기
                HStack(spacing: clipSpacing) {
                    ForEach(clips) { clip in
                        ClipTrimmingView(
                            clip: clip,
                            isDragging: $isDragging,
                            onToggleTrimming: { onToggleTrimming(clip.id) },
                            onTrimChanged:   { s,e in onTrimChanged(clip.id, s, e) }
                        )
                    }
                }
                .padding(.horizontal, halfW)
                // 플레이헤드(가운데)에 현재 프레임이 오도록
                .offset(x: -CGFloat(playHeadPosition) * pxPerSecond)
                .frame(width: geo.size.width + CGFloat(totalDuration) * pxPerSecond, // content width 크게 잡아두고
                       height: timelineHeight,
                       alignment: .leading)
                .clipped()

                // 중앙 고정 플레이헤드
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 2, height: timelineHeight)
                    .position(x: halfW, y: timelineHeight/2)
            }
        }
        .frame(height: timelineHeight)
    }
}
