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
        
        ForEach(Array(clips.enumerated()), id: \.offset) { index, item in
            HStack {
                Circle()
                if index != clips.count - 1 {
                    Rectangle()
                }
            }
        }
        
        GeometryReader { geo in
            let halfWidth = geo.size.width / 2
            HStack(alignment: .center, spacing: 0) {
                ForEach(Array(clips.enumerated()), id: \.offset) { index, clip in
                    
                    ClipTrimmingView(
                        clip: clip,
                        isDragging: $isDragging,
                        onToggleTrimming: { onToggleTrimming(clip.id) },
                        onTrimChanged:   { s,e in onTrimChanged(clip.id, s, e) }
                    )
                    
                    // 이어져있는것처럼 만들어주는 작은 선 컴포넌트
                    if index != clips.count - 1 {
                        Rectangle()
                            .frame(width: 2, height: 8)
                            .foregroundStyle(SnappieColor.primaryLight)
                    }
                }
                Button(action: onAddClipTapped) {
                    Image("union")
                        .padding(.horizontal, 16)
                        .frame(height: timelineHeight)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(SnappieColor.primaryLight)
                        )
                }
                .padding(.leading, 2)
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
