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
    let state: TrimmingState
    let actions: TrimmingActions
    @Binding var isDragging: Bool

    var body: some View {
        /// 내부 상수 선언
        let totalWidth: CGFloat = TimelineConstants.totalWidth
        let thumbnailLineWidth: CGFloat = TimelineConstants.thumbnailLineWidth
        let handleWidth: CGFloat = TimelineConstants.handleWidth
        let thumbnailHeight: CGFloat = TimelineConstants.thumbnailHeight

        let thumbnailUnitWidth = state.thumbnailUnitWidth
        let startX = max(0, state.startX)
        let endX = max(startX + 1, state.endX)
        let duration = state.duration

        ZStack(alignment: .leading) {
            // 1. 썸네일 라인 + 어두운 좌우 핸들
            HStack(spacing: 0) {
                TrimmingHandleView(isStart: true)

                HStack(spacing: 0) {
                    ForEach(Array(state.thumbnails.enumerated()), id: \.offset) { _, image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: thumbnailUnitWidth, height: thumbnailHeight)
                    }
                }
                .clipped()

                TrimmingHandleView(isStart: false)
            }
            .frame(width: totalWidth, height: TimelineConstants.thumbnailHeight)

            // 2. 트리밍 라인 박스
            Rectangle()
                .stroke(SnappieColor.primaryNormal, lineWidth: 2)
                .frame(width: thumbnailLineWidth, height: TimelineConstants.trimmingBoxHeight)
                .position(x: thumbnailLineWidth / 2 + handleWidth, y: thumbnailHeight / 2)

            // 3-1. 어두운 오버레이 (좌측)
            UnevenRoundedRectangle(
                topLeadingRadius: 6,
                bottomLeadingRadius: 6
            )
            .fill(SnappieColor.darkHeavy.opacity(0.6))
            .frame(width: startX, height: thumbnailHeight)

            // 3-2. 어두운 오버레이 (우측)
            UnevenRoundedRectangle(
                bottomTrailingRadius: 6,
                topTrailingRadius: 6
            )
            .fill(SnappieColor.darkHeavy.opacity(0.6))
            .frame(width: max(0, thumbnailLineWidth + handleWidth - endX), height: thumbnailHeight)
            .offset(x: endX)

            // 4. 트리밍 박스
            Rectangle()
                .stroke(SnappieColor.primaryNormal, lineWidth: 2)
                .frame(width: endX - startX, height: TimelineConstants.trimmingBoxHeight)
                .position(x: (startX + endX) / 2, y: thumbnailHeight / 2)

            // 5-1. 밝은 핸들 - 왼쪽 (드래그 가능)
            TrimmingHandleView(isStart: true)
                .position(x: startX - handleWidth / 2, y: thumbnailHeight / 2)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            isDragging = true
                            actions.pause()

                            let x = gesture.location.x - handleWidth
                            let ratio = max(0, min(x / thumbnailLineWidth, 1))
                            let newStart = min(ratio * duration, state.endPoint - 0.1)

                            actions.updateStart(newStart)
                        }
                        .onEnded { _ in
                            isDragging = false
                            actions.seek(state.startPoint)
                        }
                )

            // 5-2. 밝은 핸들 - 오른쪽 (드래그 가능)
            TrimmingHandleView(isStart: false)
                .position(x: endX + handleWidth / 2, y: thumbnailHeight / 2)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            isDragging = true
                            actions.pause()

                            let x = gesture.location.x - handleWidth
                            let ratio = max(0, min(x / thumbnailLineWidth, 1))
                            let newEnd = max(ratio * duration, state.startPoint + 0.1)

                            actions.updateEnd(newEnd)
                        }
                        .onEnded { _ in
                            isDragging = false
                            actions.seek(state.endPoint)
                        }
                )
        }
        .frame(width: totalWidth, height: TimelineConstants.thumbnailHeight)
        .contentShape(Rectangle())
        .gesture(
            // 드래그 제스처
            DragGesture()
                .onChanged { gesture in
                    isDragging = true
                    actions.pause()

                    let locationRatio = gesture.location.x / TimelineConstants.thumbnailLineWidth
                    let centerTime = locationRatio * state.duration
                    let currentCenter = (state.startPoint + state.endPoint) / 2
                    let delta = centerTime - currentCenter

                    actions.shiftTrimmingRange(delta)

                    Task {
                        await actions.updatePreviewImage(state.startPoint)
                    }
                }
                .onEnded { _ in
                    isDragging = false
                    actions.seek(state.startPoint)
                }
        )
    }
}
