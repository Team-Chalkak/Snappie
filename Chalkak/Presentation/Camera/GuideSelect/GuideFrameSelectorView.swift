//
//  GuideFrameSelectorView.swift
//  Chalkak
//
//  Created by bishoe01 on 12/26/25.
//

import SwiftUI

struct GuideFrameSelectorView: View {
    @ObservedObject var editViewModel: ClipEditViewModel
    @Binding var isDragging: Bool

    var body: some View {
        let totalWidth: CGFloat = TimelineConstants.totalWidth
        let thumbnailLineWidth: CGFloat = TimelineConstants.thumbnailLineWidth
        let handleWidth: CGFloat = TimelineConstants.handleWidth
        let thumbnailHeight: CGFloat = TimelineConstants.thumbnailHeight

        let thumbnailUnitWidth = editViewModel.thumbnailUnitWidth(for: thumbnailLineWidth)
        // 박스가 오른쪽 핸들 넘지 않게 제한
        let rawFrameX = editViewModel.startX(thumbnailLineWidth: thumbnailLineWidth, handleWidth: handleWidth)
        let maxFrameX = handleWidth + thumbnailLineWidth - TimelineConstants.frameBoxWidth
        let frameX = max(handleWidth, min(rawFrameX, maxFrameX))
        let duration = editViewModel.duration

        ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                HandleCapsule(isLeading: true)

                HStack(spacing: 0) {
                    ForEach(Array(editViewModel.thumbnails.enumerated()), id: \.offset) { _, image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: thumbnailUnitWidth, height: thumbnailHeight)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .background(SnappieColor.darkNormal)

                HandleCapsule(isLeading: false)
            }
            .frame(width: totalWidth, height: TimelineConstants.thumbnailHeight)

            // 가이드 프레임
            RoundedRectangle(cornerRadius: TimelineConstants.frameBoxCornerRadius)
                .stroke(TimelineConstants.frameBoxStrokeColor, lineWidth: 2)
                .frame(width: TimelineConstants.frameBoxWidth, height: TimelineConstants.frameBoxHeight)
                .position(
                    x: frameX + TimelineConstants.frameBoxOffsetX,
                    y: thumbnailHeight / 2
                )
                .allowsHitTesting(false)

            Image("silhouette")
                .resizable()
                .scaledToFit()
                .frame(width: 146, height: 16)
                .position(
                    x: frameX + TimelineConstants.frameBoxOffsetX,
                    y: thumbnailHeight / 2 + TimelineConstants.frameBoxHeight / 2 + 12
                )
                .allowsHitTesting(false)
        }
        .frame(width: totalWidth, height: TimelineConstants.thumbnailHeight)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(SnappieColor.darkNormal, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { gesture in
                    isDragging = true
                    editViewModel.player.pause()
                    editViewModel.isPlaying = false

                    let draggedFrameX = gesture.location.x
                    let minFrameX = handleWidth
                    let maxFrameX = handleWidth + thumbnailLineWidth - TimelineConstants.frameBoxWidth
                    let clampedFrameX = max(minFrameX, min(draggedFrameX, maxFrameX))

                    let ratio = (clampedFrameX - handleWidth) / (thumbnailLineWidth - TimelineConstants.frameBoxWidth)
                    let newStart = ratio * duration

                    editViewModel.updateStart(newStart)
                }
                .onEnded { _ in
                    isDragging = false
                    editViewModel.seek(to: editViewModel.startPoint)
                }
        )
    }
}

private struct HandleCapsule: View {
    let isLeading: Bool

    var body: some View {
        UnevenRoundedRectangle(
            cornerRadii: .init(
                topLeading: isLeading ? 6 : 0,
                bottomLeading: isLeading ? 6 : 0,
                bottomTrailing: isLeading ? 0 : 6,
                topTrailing: isLeading ? 0 : 6
            )
        )
        .fill(SnappieColor.darkNormal)
        .frame(width: TimelineConstants.handleWidth, height: TimelineConstants.thumbnailHeight)
    }
}
