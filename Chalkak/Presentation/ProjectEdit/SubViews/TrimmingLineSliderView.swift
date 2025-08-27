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
    let onToggleTrimming: (String) -> Void
    let onTrimChanged: (String, Double, Double) -> Void
    let onMove: (IndexSet, Int) -> Void
    let onAddClipTapped: () -> Void

    private let pxPerSecond: CGFloat = 50
    private let clipSpacing: CGFloat = 8
    private let timelineHeight: CGFloat = 60
    private let rulerHeight: CGFloat = 23
    private let timeBoardPadding: CGFloat = 11

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 타임 보드
                ProjectTimeBoardView(
                    totalDuration: totalDuration,
                    playHeadPosition: playHeadPosition,
                    dragOffset: dragOffset,
                    pxPerSecond: pxPerSecond,
                    rulerHeight: rulerHeight
                )
                .padding(.bottom, timeBoardPadding)
                
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
                    onToggleTrimming: onToggleTrimming,
                    onTrimChanged: onTrimChanged,
                    onMove: onMove,
                    onAddClipTapped: onAddClipTapped
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
            }
            .frame(height: rulerHeight + timelineHeight)
            
            // Playhead
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.matcha50)
                .frame(width: 2, height: rulerHeight + timelineHeight + timeBoardPadding)
                .frame(maxWidth: .infinity, alignment: .center)
                .allowsHitTesting(false)
        }
        .frame(height: rulerHeight + timeBoardPadding + timelineHeight)
    }
}
