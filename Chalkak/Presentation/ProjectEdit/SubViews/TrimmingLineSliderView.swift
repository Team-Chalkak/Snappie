//
//  TrimmingLineSliderView.swift
//  Chalkak
//
//  Created by 배현진 on 7/24/25.
//

import SwiftUI

struct TrimminglineSliderView: View {
    @Binding var clips: [EditableClip]
    @Binding var playHeadPosition: Double
    @Binding var isDragging: Bool
    @Binding var selectedClipID: String?
    let isPlaying: Bool
    let totalDuration: Double

    let onSeek: (Double) -> Void
    let onMove: (IndexSet, Int) -> Void
    let onAddClipTapped: () -> Void
    let onDragStateChanged: (Bool) -> Void
    let onClipTapped: (String) -> Void

    // 클립별 duration에 따른 변환 함수
    let pixelOffsetForTime: (Double) -> CGFloat
    let timeForPixelOffset: (CGFloat) -> Double

    private let clipSpacing: CGFloat = 3
    private let sliderHeight: CGFloat = 130
    private let clipHeight: CGFloat = 97

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // 타임 라인
            ProjectTimelineView(
                clips: $clips,
                isDragging: $isDragging,
                selectedClipID: $selectedClipID,
                playHeadPosition: playHeadPosition,
                totalDuration: totalDuration,
                dragOffset: dragOffset,
                pixelOffsetForTime: pixelOffsetForTime,
                clipSpacing: clipSpacing,
                onMove: onMove,
                onAddClipTapped: onAddClipTapped,
                onDragStateChanged: onDragStateChanged,
                onClipTapped: onClipTapped
            )
            .frame(height: clipHeight)
            .background(
                Rectangle()
                    .fill(SnappieColor.containerFillNormal)
                    .frame(maxWidth: .infinity)
            )
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        isDragging = true;
                        dragOffset = gesture.translation.width
                    }
                    .onEnded { gesture in
                        isDragging = false

                        // 현재 playHead의 픽셀 위치 계산
                        let currentPixelOffset = pixelOffsetForTime(playHeadPosition)

                        // 드래그 후 픽셀 위치 계산 (왼쪽 드래그는 음수)
                        let newPixelOffset = currentPixelOffset - gesture.translation.width

                        // 픽셀을 시간으로 변환
                        var newTime = timeForPixelOffset(newPixelOffset)
                        newTime = min(max(0, newTime), totalDuration)

                        onSeek(newTime)
                        dragOffset = 0
                    }
            )
            
            // Playhead
            PlayheadView()
                .frame(maxWidth: .infinity, alignment: .center)
                .allowsHitTesting(false)
        }
        .frame(height: sliderHeight)
    }
}
