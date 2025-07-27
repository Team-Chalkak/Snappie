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
    
    /// 추가된 클로저
    let onAddClipTapped: () -> Void

    private let pxPerSecond: CGFloat = 50
    private let clipSpacing: CGFloat = 8
    private let timelineHeight: CGFloat = 60

    var body: some View {
        GeometryReader { geo in
            let halfW = geo.size.width / 2

            ZStack(alignment: .leading) {
                HStack(spacing: clipSpacing) {
                    // 기존 클립들
                    ForEach(clips) { clip in
                        ClipTrimmingView(
                            clip: clip,
                            isDragging: $isDragging,
                            onToggleTrimming: { onToggleTrimming(clip.id) },
                            onTrimChanged:   { s, e in onTrimChanged(clip.id, s, e) }
                        )
                    }

                    // + 버튼
                    Button(action: onAddClipTapped) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.gray, lineWidth: 1)
                                .frame(width: timelineHeight, height: timelineHeight)
                            Image(systemName: "plus")
                                .font(.title2)
                        }
                    }
                    .frame(width: timelineHeight, height: timelineHeight)
                }
                .padding(.horizontal, halfW)
                .offset(x: -CGFloat(playHeadPosition) * pxPerSecond)
                .frame(
                    width: geo.size.width + CGFloat(totalDuration) * pxPerSecond,
                    height: timelineHeight,
                    alignment: .leading
                )
                .clipped()

                // 플레이헤드(가운데)
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 2, height: timelineHeight)
                    .position(x: halfW, y: timelineHeight/2)
            }
        }
        .frame(height: timelineHeight)
    }
}
