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
    let isPlaying: Bool
    let totalDuration: Double

    let onSeek: (Double) -> Void
    let onMove: (IndexSet, Int) -> Void
    let onAddClipTapped: () -> Void
    let onDragStateChanged: (Bool) -> Void

    private let pxPerSecond: CGFloat = 50
    private let clipSpacing: CGFloat = 8
    private let sliderHeight: CGFloat = 130
    private let timelineHeight: CGFloat = 97

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // 타임 라인
            ProjectTimelineView(
                clips: $clips,
                isDragging: $isDragging,
                playHeadPosition: playHeadPosition,
                totalDuration: totalDuration,
                dragOffset: dragOffset,
                pxPerSecond: pxPerSecond,
                clipSpacing: clipSpacing,
                timelineHeight: timelineHeight,
                onMove: onMove,
                onAddClipTapped: onAddClipTapped,
                onDragStateChanged: onDragStateChanged
            )
            .frame(height: timelineHeight)
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
                        let delta = -Double(gesture.translation.width / pxPerSecond)
                        var newTime = playHeadPosition + delta
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
