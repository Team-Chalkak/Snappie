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
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 6)
                .stroke(SnappieColor.primaryNormal, lineWidth: 2)
                .frame(width: fullWidth+40, height: thumbnailHeight)

            ProjectTrimmingHandle(
                isStart: true,
                fullHeight: thumbnailHeight,
                fullWidth: fullWidth,
                isDragging: $isDragging,
                onTrimChanged: onTrimChanged,
                clip: clip
            )
            ProjectTrimmingHandle(
                isStart: false,
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
