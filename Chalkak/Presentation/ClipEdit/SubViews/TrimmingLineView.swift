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
 - 썸네일 라인 표시
 - 트리밍 범위 시각화 및 드래그 제스처 처리
 - 트리밍 시작/종료 지점에 따른 프리뷰 이미지 갱신

 ## 호출 위치
 - TrimmingControlView 내부에서 사용
 - 호출 예시 : TrimmingLineView(editViewModel: editViewModel, isDragging: $isDragging)
 */
struct TrimmingLineView: View {
    @ObservedObject var editViewModel: ClipEditViewModel
    @Binding var isDragging: Bool

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let thumbnailWidth = editViewModel.thumbnailWidth(for: totalWidth)
            let startX = editViewModel.startX(for: totalWidth)
            let endX = editViewModel.endX(for: totalWidth)
            let trimmingWidth = editViewModel.trimmingWidth(for: totalWidth)

            ZStack(alignment: .leading) {
                // 1. 썸네일 라인
                HStack(spacing: 0) {
                    ForEach(editViewModel.thumbnails, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: thumbnailWidth, height: Layout.thumbnailHeight)
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
                RoundedRectangle(cornerRadius: Layout.trimmingCornerRadius)
                    .strokeBorder(Color.yellow, lineWidth: Layout.trimmingLineWidth)
                    .frame(width: trimmingWidth, height: Layout.thumbnailHeight)
                    .position(x: startX + trimmingWidth / 2, y: Layout.timelineY)

                // 4. 핸들 (좌/우)
                draggableHandleView(positionX: startX, totalWidth: totalWidth, isStart: true)
                draggableHandleView(positionX: endX, totalWidth: totalWidth, isStart: false)

                // 5. 미리보기 강조 박스
                RoundedRectangle(cornerRadius: Layout.previewCornerRadius)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: Layout.previewBoxWidth, height: Layout.previewBoxHeight)
                    .position(x: startX + Layout.previewOffsetX, y: Layout.timelineY)
            }
        }
        .frame(height: Layout.timelineHeight)
    }

    //MARK: - Function
    /// 핸들 공통 View + 제스처
    private func draggableHandleView(positionX: CGFloat, totalWidth: CGFloat, isStart: Bool) -> some View {
        handleView()
            .position(x: positionX, y: Layout.timelineY)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        isDragging = true
                        editViewModel.player?.pause()
                        editViewModel.isPlaying = false

                        let locationX = gesture.location.x / totalWidth * editViewModel.duration

                        if isStart {
                            let newStart = max(
                                0,
                                min(locationX, editViewModel.endPoint - 0.1)
                            )
                            editViewModel.updateStart(newStart)
                        } else {
                            let newEnd = min(
                                editViewModel.duration,
                                max(locationX, editViewModel.startPoint + 0.1)
                            )
                            editViewModel.updateEnd(newEnd)
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                        let seekTime = isStart ? editViewModel.startPoint : editViewModel.endPoint
                        editViewModel.seek(to: seekTime)
                    }
            )
    }

    /// 핸들 UI 재사용 함수
    private func handleView() -> some View {
        RoundedRectangle(cornerRadius: Layout.handleCornerRadius)
            .fill(Color.yellow)
            .frame(width: Layout.handleWidth, height: Layout.handleHeight)
    }
}

// MARK: - Layout Constants

private extension TrimmingLineView {
    enum Layout {
        /// 썸네일
        static let thumbnailHeight: CGFloat = 60

        /// 타임라인 위치
        static let timelineY: CGFloat = 30
        static let timelineHeight: CGFloat = 60

        /// 트리밍 테두리
        static let trimmingCornerRadius: CGFloat = 4
        static let trimmingLineWidth: CGFloat = 2

        /// 핸들
        static let handleCornerRadius: CGFloat = 3
        static let handleWidth: CGFloat = 10
        static let handleHeight: CGFloat = 60

        /// 영상첫번째 프레임 표시
        static let previewCornerRadius: CGFloat = 6
        static let previewBoxWidth: CGFloat = 34
        static let previewBoxHeight: CGFloat = 57
        static let previewOffsetX: CGFloat = 20
    }
}
