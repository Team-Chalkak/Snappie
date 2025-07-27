//
//  ProjectTimelineView.swift
//  Chalkak
//
//  Created by 배현진 on 7/28/25.
//

import SwiftUI

struct ProjectTimelineView: View {
    @Binding var clips: [EditableClip]
    @Binding var isDragging: Bool
    let playHeadPosition: Double
    let totalDuration: Double
    let dragOffset: CGFloat

    let pxPerSecond: CGFloat
    let clipSpacing: CGFloat
    let timelineHeight: CGFloat

    let onToggleTrimming: (String) -> Void
    let onTrimChanged: (String, Double, Double) -> Void
    let onAddClipTapped: () -> Void

    var body: some View {
        GeometryReader { geo in
            let halfWidth = geo.size.width / 2
            HStack(spacing: clipSpacing) {
                ForEach(clips) { clip in
                    ClipTrimmingView(
                        clip: clip,
                        isDragging: $isDragging,
                        onToggleTrimming: { onToggleTrimming(clip.id) },
                        onTrimChanged:   { s,e in onTrimChanged(clip.id, s, e) }
                    )
                }
                Button(action: onAddClipTapped) {
                    // TODO: - 버튼 디자인 변경하면서 Stack 제거
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray, lineWidth: 1)
                            .frame(width: timelineHeight, height: timelineHeight)
                        Image(systemName: "plus").font(.title2)
                    }
                }
                .frame(width: timelineHeight, height: timelineHeight)
            }
            .padding(.horizontal, halfWidth)
            .offset(x: -CGFloat(playHeadPosition) * pxPerSecond + dragOffset)
            .frame(
                width: geo.size.width + CGFloat(totalDuration) * pxPerSecond,
                height: timelineHeight,
                alignment: .leading
            )
            .clipped()
        }
        .frame(height: timelineHeight)
    }
}
