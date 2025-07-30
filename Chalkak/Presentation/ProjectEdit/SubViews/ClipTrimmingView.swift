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
    let onToggleTrimming: () -> Void
    let onTrimChanged: (Double, Double) -> Void

    private let pxPerSecond: CGFloat = 50
    private let clipSpacing: CGFloat = 8
    private let thumbnailHeight: CGFloat = 60

    private var fullWidth: CGFloat {
        if clip.isTrimming {
            CGFloat(clip.originalDuration) * pxPerSecond
        } else {
            CGFloat(clip.trimmedDuration) * pxPerSecond
        }
    }

    var body: some View {
        ZStack(alignment: .leading) {
            ProjectThumbnailsView(clip: clip, fullWidth: fullWidth)
                .onTapGesture { onToggleTrimming() }
                .padding(.horizontal, clipSpacing/2)

            if clip.isTrimming {
                ProjectTrimmingLineView(
                    clip: clip,
                    fullWidth: fullWidth,
                    thumbnailHeight: thumbnailHeight,
                    isDragging: $isDragging,
                    onTrimChanged: onTrimChanged
                )
            }
        }
        .frame(width: fullWidth, height: thumbnailHeight)
    }
}
