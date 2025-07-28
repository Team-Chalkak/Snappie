//
//  ProjectTrimmingHandle.swift
//  Chalkak
//
//  Created by 배현진 on 7/28/25.
//

import SwiftUI

struct ProjectTrimmingHandle: View {
    let isStart: Bool
    let leftW: CGFloat
    let midW: CGFloat
    let fullHeight: CGFloat
    let fullWidth: CGFloat
    @Binding var isDragging: Bool
    let onTrimChanged: (Double, Double) -> Void
    let clip: EditableClip

    var body: some View {
        let size: CGFloat = 10
        let xOffset = isStart ? leftW : (leftW + midW - size)

        RoundedRectangle(cornerRadius: 3)
            .fill(Color.yellow)
            .frame(width: size, height: fullHeight)
            .offset(x: xOffset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        isDragging = true
                        let ratio = min(max(gesture.location.x / fullWidth, 0), 1)
                        let time = Double(ratio) * clip.originalDuration
                        if isStart {
                            let newStart = min(time, clip.endPoint - 0.1)
                            onTrimChanged(newStart, clip.endPoint)
                        } else {
                            let newEnd = max(time, clip.startPoint + 0.1)
                            onTrimChanged(clip.startPoint, newEnd)
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
    }
}
