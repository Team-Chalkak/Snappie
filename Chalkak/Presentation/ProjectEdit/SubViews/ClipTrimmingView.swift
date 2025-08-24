//
//  ClipTrimmingView.swift
//  Chalkak
//
//  Created by 배현진 on 7/24/25.
//

import SwiftUI
import AVFoundation

struct ClipTrimmingView: View {
    let clip: EditableClip
    @Binding var isDragging: Bool
    let isLastClip: Bool = false
    let onToggleTrimming: () -> Void
    let onTrimChanged: (Double, Double) -> Void

    private let pxPerSecond: CGFloat = 50
    private let thumbnailHeight: CGFloat = 60
    
    // 실제 비디오 시간에 해당하는 너비(계산용)
    private var timeBasedWidth: CGFloat {
        CGFloat(clip.trimmedDuration) * pxPerSecond
    }

    var body: some View {
        // 썸네일뷰
        ProjectThumbnailsView(
            clip: clip,
            fullWidth: timeBasedWidth
        )
        .onTapGesture { onToggleTrimming() }
        .overlay {
            // 트리밍 라인 뷰
            if clip.isTrimming {
                ProjectTrimmingLineView(
                    clip: clip,
                    fullWidth: timeBasedWidth,
                    thumbnailHeight: thumbnailHeight,
                    isDragging: $isDragging,
                    onTrimChanged: onTrimChanged
                )
            }
        }
        .frame(
            width: timeBasedWidth,
            height: thumbnailHeight
        )
        .zIndex(clip.isTrimming ? 1 : 0)
    }
}
