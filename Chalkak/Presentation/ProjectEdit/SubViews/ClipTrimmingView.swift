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

    /// 뷰 전체 너비 (고정)
    private var fullWidth: CGFloat {
        CGFloat(clip.originalDuration) * pxPerSecond
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // 1) 전체 썸네일
            HStack(spacing: 0) {
                ForEach(clip.thumbnails.indices, id: \.self) { i in
                    Image(uiImage: clip.thumbnails[i])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(
                            width: fullWidth / CGFloat(clip.thumbnails.count),
                            height: thumbnailHeight
                        )
                        .clipped()
                }
            }
            .frame(width: fullWidth, height: thumbnailHeight)
            .contentShape(Rectangle())
            .onTapGesture { onToggleTrimming() }
            .padding(.horizontal, clipSpacing/2)

            // 2) 마스크 & 테두리 & 핸들 (트리밍 모드일 때만)
            if clip.isTrimming {
                let leftW  = CGFloat(clip.startPoint / clip.originalDuration) * fullWidth
                let midW   = CGFloat(clip.trimmedDuration / clip.originalDuration) * fullWidth
                let rightW = fullWidth - leftW - midW

                // 어두운 마스크
                HStack(spacing: 0) {
                    Color.black.opacity(0.5).frame(width: leftW)
                    Color.clear.frame(width: midW)
                    Color.black.opacity(0.5).frame(width: rightW)
                }
                .frame(width: fullWidth, height: thumbnailHeight)

                // 노란 테두리
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.yellow, lineWidth: 2)
                    .frame(width: midW, height: thumbnailHeight)
                    .offset(x: leftW)

                // 핸들 (시작/끝)
                handle(isStart: true,  leftW: leftW, midW: midW)
                handle(isStart: false, leftW: leftW, midW: midW)
            }
        }
        .frame(width: fullWidth, height: thumbnailHeight)
    }

    @ViewBuilder
    private func handle(isStart: Bool, leftW: CGFloat, midW: CGFloat) -> some View {
        let size: CGFloat = 10
        let xOffset = isStart
            ? leftW
            : (leftW + midW - size)

        RoundedRectangle(cornerRadius: 3)
            .fill(Color.yellow)
            .frame(width: size, height: thumbnailHeight)
            .offset(x: xOffset)
            .gesture(
                DragGesture()
                    .onChanged { g in
                        isDragging = true
                        let ratio = min(max(g.location.x / fullWidth, 0), 1)
                        let t = Double(ratio) * clip.originalDuration
                        if isStart {
                            let newStart = min(t, clip.endPoint - 0.1)
                            onTrimChanged(newStart, clip.endPoint)
                        } else {
                            let newEnd = max(t, clip.startPoint + 0.1)
                            onTrimChanged(clip.startPoint, newEnd)
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
    }
}
