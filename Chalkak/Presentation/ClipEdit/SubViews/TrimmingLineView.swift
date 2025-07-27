//
//  TrimmingLineView.swift
//  Chalkak
//
//  Created by Youbin on 7/15/25.
//

import SwiftUI

/**
 TrimmingLineView: 영상 트리밍 라인 UI

 썸네일 라인을 기반으로 사용자가 시작/종료 시점을 조절할 수 있도록 돕는 타임라인 뷰.
 좌우 핸들을 드래그해 트리밍 범위를 설정하며, 미리보기 이미지도 실시간으로 갱신된다.

 ## 주요 기능
 - 썸네일 라인 표시 (고정 305pt)
 - 트리밍 범위 시각화 및 드래그 제스처 처리
 - 트리밍 시작/종료 지점에 따른 프리뷰 이미지 갱신

 ## 호출 위치
 - TrimmingControlView 내부에서 사용
 - 호출 예시 : TrimmingLineView(editViewModel: editViewModel, isDragging: $isDragging)
 */
import SwiftUI

struct TrimmingLineView: View {
    @ObservedObject var editViewModel: ClipEditViewModel
    @Binding var isDragging: Bool

    private let totalWidth: CGFloat = 345
    private let thumbnailWidth: CGFloat = Layout.thumbnailWidth
    private let handleWidth: CGFloat = Layout.handleWidth

    var body: some View {
        let duration = editViewModel.duration
        let startRatio = editViewModel.startPoint / duration
        let endRatio = editViewModel.endPoint / duration

        let startX = handleWidth + startRatio * thumbnailWidth
        let endX = handleWidth + endRatio * thumbnailWidth

        ZStack(alignment: .leading) {
            // 썸네일 라인 + 어두운 좌우 핸들
            HStack(spacing: 0) {
                TrimmingHandleView(isStart: true)

                HStack(spacing: 0) {
                    ForEach(Array(editViewModel.thumbnails.enumerated()), id: \.offset) { _, image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: thumbnailWidth / CGFloat(editViewModel.thumbnails.count), height: Layout.thumbnailHeight)
                    }
                }
                .clipped()

                TrimmingHandleView(isStart: false)
            }
            .frame(width: totalWidth, height: Layout.thumbnailHeight)

            // 어두운 오버레이 (좌측)
            UnevenRoundedRectangle(
                topLeadingRadius: 6,
                bottomLeadingRadius: 6
            )
            .fill(SnappieColor.darkHeavy.opacity(0.6))
            .frame(width: startX, height: Layout.thumbnailHeight)

            // 어두운 오버레이 (우측)
            UnevenRoundedRectangle(
                bottomTrailingRadius: 6,
                topTrailingRadius: 6
            )
            .fill(SnappieColor.darkHeavy.opacity(0.6))
            .frame(width: totalWidth - endX, height: Layout.thumbnailHeight)
            .position(x: endX + (totalWidth - endX) / 2, y: Layout.thumbnailHeight / 2)

            // 트리밍 박스
            Rectangle()
                .stroke(SnappieColor.primaryNormal, lineWidth: 2)
                .frame(width: endX - startX, height: 58)
                .position(x: (startX + endX) / 2, y: Layout.thumbnailHeight / 2)

            // 밝은 핸들 - 왼쪽 (드래그 가능)
            TrimmingHandleView(isStart: true)
                .position(x: startX - handleWidth / 2, y: Layout.thumbnailHeight / 2)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            isDragging = true
                            editViewModel.player?.pause()
                            editViewModel.isPlaying = false

                            let x = gesture.location.x - handleWidth
                            let ratio = max(0, min(x / thumbnailWidth, 1))
                            let newStart = min(ratio * duration, editViewModel.endPoint - 0.1)

                            editViewModel.updateStart(newStart)
                        }
                        .onEnded { _ in
                            isDragging = false
                            editViewModel.seek(to: editViewModel.startPoint)
                        }
                )

            // 밝은 핸들 - 오른쪽 (드래그 가능)
            TrimmingHandleView(isStart: false)
                .position(x: endX + handleWidth / 2, y: Layout.thumbnailHeight / 2)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            isDragging = true
                            editViewModel.player?.pause()
                            editViewModel.isPlaying = false

                            let x = gesture.location.x - handleWidth
                            let ratio = max(0, min(x / thumbnailWidth, 1))
                            let newEnd = max(ratio * duration, editViewModel.startPoint + 0.1)

                            editViewModel.updateEnd(newEnd)
                        }
                        .onEnded { _ in
                            isDragging = false
                            editViewModel.seek(to: editViewModel.endPoint)
                        }
                )
        }
        .frame(width: totalWidth, height: Layout.thumbnailHeight)
    }
}

// MARK: - Layout Constants
private extension TrimmingLineView {
    enum Layout {
        // 썸네일
        static let thumbnailHeight: CGFloat = 60
        static let thumbnailWidth: CGFloat = 305
        
        // 핸들
        static let handleWidth: CGFloat = 20

        // 첫번째 프레임 강조 박스
        static let frameBoxCornerRadius: CGFloat = 6
        static let frameBoxWidth: CGFloat = 34
        static let frameBoxHeight: CGFloat = 57
        static let frameBoxOffsetX: CGFloat = 21
        static let frameBoxStrokeColor: Color = .white
    }
}
