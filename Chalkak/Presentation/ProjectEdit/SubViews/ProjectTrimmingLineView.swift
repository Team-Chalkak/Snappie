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
    let trimmedWidth: CGFloat
    let thumbnailHeight: CGFloat
    @Binding var isDragging: Bool
    let onTrimChanged: (Double, Double) -> Void
    let onDragStateChanged: (Bool) -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 6)
                .stroke(SnappieColor.primaryNormal, lineWidth: 2)
                .frame(width: trimmedWidth+40, height: thumbnailHeight)

            ProjectTrimmingHandle(
                isStart: true,
                fullHeight: thumbnailHeight,
                fullWidth: fullWidth,
                trimmedWidth: trimmedWidth,
                isDragging: $isDragging,
                onTrimChanged: onTrimChanged,
                onDragStateChanged: onDragStateChanged,
                clip: clip
            )
            ProjectTrimmingHandle(
                isStart: false,
                fullHeight: thumbnailHeight,
                fullWidth: fullWidth,
                trimmedWidth: trimmedWidth,
                isDragging: $isDragging,
                onTrimChanged: onTrimChanged,
                onDragStateChanged: onDragStateChanged,
                clip: clip
            )
            .offset(x: 20)
        }
    }
}
