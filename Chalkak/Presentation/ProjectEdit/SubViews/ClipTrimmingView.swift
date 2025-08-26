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
    
    /// 기준이 되는 원본 길이
    private var originalTimeBasedWidth: CGFloat {
        CGFloat(clip.originalDuration) * pxPerSecond
    }
    
    /// 트리밍된 실제 표시 너비
    private var trimmedDisplayWidth: CGFloat {
        CGFloat(clip.trimmedDuration) * pxPerSecond
    }

    var body: some View {
        // 원본 크기로 썸네일 그리기
        ProjectThumbnailsView(
            clip: clip,
            fullWidth: originalTimeBasedWidth
        )
        // 트리밍된 부분만 보이도록 마스킹
        .mask {
            Rectangle()
                .frame(width: trimmedDisplayWidth, height: thumbnailHeight)
        }
        .onTapGesture { onToggleTrimming() }
        .frame(
            width: trimmedDisplayWidth,
            height: thumbnailHeight
        )
        .clipShape(RoundedRectangle(cornerRadius: clip.isTrimming ? 0 : 6))
        .overlay {
            // 트리밍 라인 뷰
            if clip.isTrimming {
                ProjectTrimmingLineView(
                    clip: clip,
                    fullWidth: trimmedDisplayWidth,
                    thumbnailHeight: thumbnailHeight,
                    isDragging: $isDragging,
                    onTrimChanged: onTrimChanged
                )
            }
        }
        .zIndex(clip.isTrimming ? 1 : 0)
    }
}
