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
    
    private let unionButtonWidth: CGFloat = 48

    var body: some View {
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
                }
                
                Button(action: onAddClipTapped) {
                    Image("union")
                        .frame(width: unionButtonWidth, height: timelineHeight, alignment: .center)
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
                width: getTimelineFullWidth(geoWidth: geo.size.width),
                height: timelineHeight,
                alignment: .leading
            )
        }
        .frame(height: timelineHeight)
    }
}

extension ProjectTimelineView {
    func getTimelineFullWidth(geoWidth: CGFloat) -> CGFloat {
        let videoRangeWidth = CGFloat(totalDuration) * pxPerSecond
        
        return geoWidth + videoRangeWidth + unionButtonWidth
    }
}
