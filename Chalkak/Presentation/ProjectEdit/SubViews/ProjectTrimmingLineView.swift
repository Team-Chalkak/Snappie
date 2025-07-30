//
//  ProjectTrimmingLineView.swift
//  Chalkak
//
//  Created by 배현진 on 7/28/25.
//

import SwiftUI

struct ProjectTrimmingLineView: View {
    let clip: EditableClip
    let fullWidth: CGFloat
    let thumbnailHeight: CGFloat
    @Binding var isDragging: Bool
    let onTrimChanged: (Double, Double) -> Void

    var body: some View {
        let leftW  = CGFloat(clip.startPoint / clip.originalDuration) * fullWidth
        let midW   = CGFloat(clip.trimmedDuration / clip.originalDuration) * fullWidth
        let rightW = fullWidth - leftW - midW

        ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                Color.black.opacity(0.5).frame(width: leftW)
                Color.clear.frame(width: midW)
                Color.black.opacity(0.5).frame(width: rightW)
            }
            .padding(.horizontal, 20)

            RoundedRectangle(cornerRadius: 6)
                .stroke(SnappieColor.primaryNormal, lineWidth: 2)
                .frame(width: midW+40, height: thumbnailHeight)
                .offset(x: leftW)

            ProjectTrimmingHandle(
                isStart: true,
                leftW: leftW,
                midW: midW,
                fullHeight: thumbnailHeight,
                fullWidth: fullWidth,
                isDragging: $isDragging,
                onTrimChanged: onTrimChanged,
                clip: clip
            )
            ProjectTrimmingHandle(
                isStart: false,
                leftW: leftW,
                midW: midW,
                fullHeight: thumbnailHeight,
                fullWidth: fullWidth,
                isDragging: $isDragging,
                onTrimChanged: onTrimChanged,
                clip: clip
            )
            .offset(x: 20)
        }
    }
}
