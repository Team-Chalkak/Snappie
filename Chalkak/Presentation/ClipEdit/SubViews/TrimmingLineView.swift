//
//  TrimmingLineView.swift
//  Chalkak
//
//  Created by Youbin on 7/15/25.
//

import SwiftUI

/// 트리밍 라인(썸네일 슬라이더 및 트리밍 핸들)
struct TrimmingLineView: View {
    @ObservedObject var editViewModel: ClipEditViewModel
    @Binding var isDragging: Bool

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let thumbnailCount = editViewModel.thumbnails.count
            let thumbnailWidth = totalWidth / CGFloat(thumbnailCount)
            let startX = CGFloat(editViewModel.startPoint / editViewModel.duration) * totalWidth
            let endX = CGFloat(editViewModel.endPoint / editViewModel.duration) * totalWidth
            let trimmingWidth = endX - startX

            ZStack(alignment: .leading) {
                // 1. 썸네일 라인
                HStack(spacing: 0) {
                    ForEach(editViewModel.thumbnails, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: thumbnailWidth, height: 60)
                            .clipped()
                    }
                }

                // 2. 어두운 양옆 영역
                HStack(spacing: 0) {
                    Rectangle().fill(Color.black.opacity(0.5)).frame(width: startX)
                    Rectangle().fill(Color.clear).frame(width: trimmingWidth)
                    Rectangle().fill(Color.black.opacity(0.5))
                }

                // 3. 트리밍 테두리
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.yellow, lineWidth: 2)
                    .frame(width: trimmingWidth, height: 60)
                    .position(x: startX + trimmingWidth / 2, y: 30)

                // 4. 핸들 (좌/우)
                Group {
                    handleView()
                        .position(x: startX, y: 30)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    isDragging = true
                                    editViewModel.player?.pause()
                                    editViewModel.isPlaying = false
                                    let newStart = max(
                                        0,
                                        min(gesture.location.x / totalWidth * editViewModel.duration,
                                            editViewModel.endPoint - 0.1)
                                    )
                                    editViewModel.updateStart(newStart)
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    editViewModel.seek(to: editViewModel.startPoint)
                                }
                        )

                    handleView()
                        .position(x: endX, y: 30)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    isDragging = true
                                    editViewModel.player?.pause()
                                    editViewModel.isPlaying = false
                                    let newEnd = min(
                                        editViewModel.duration,
                                        max(gesture.location.x / totalWidth * editViewModel.duration,
                                            editViewModel.startPoint + 0.1)
                                    )
                                    editViewModel.updateEnd(newEnd)
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    editViewModel.seek(to: editViewModel.endPoint)
                                }
                        )
                }

                // 5. 미리보기 강조 박스
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 34, height: 57)
                    .position(x: startX + 20, y: 30)
            }
        }
        .frame(height: 60)
    }

    private func handleView() -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.yellow)
            .frame(width: 10, height: 60)
    }
}
