//
//  ProjectTimelineView.swift
//  Chalkak
//
//  Created by 배현진 on 7/28/25.
//

import SwiftUI

struct ProjectTimelineView: View {
    @Binding var clips: [EditableClip]
    @Binding var isDragging: Bool
    let playHeadPosition: Double
    let totalDuration: Double
    let dragOffset: CGFloat

    let pxPerSecond: CGFloat
    let clipSpacing: CGFloat
    let timelineHeight: CGFloat

    let onToggleTrimming: (String) -> Void
    let onTrimChanged: (String, Double, Double) -> Void
    let onMove: (IndexSet, Int) -> Void
    let onAddClipTapped: () -> Void

    // 드래그 앤 드롭을 위한 상태 변수
    @State private var draggingClip: EditableClip?
    @State private var dragValue: DragGesture.Value?
    @State private var isDragActive = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Layer 1: The scrollable timeline
                HStack(alignment: .center, spacing: 0) {
                    ForEach(clips) { clip in
                        let isBeingDragged = (draggingClip?.id == clip.id && isDragActive)

                        ClipTrimmingView(
                            clip: clip,
                            isDragging: $isDragging,
                            onToggleTrimming: { onToggleTrimming(clip.id) },
                            onTrimChanged: { s, e in onTrimChanged(clip.id, s, e) }
                        )
                        .opacity(isBeingDragged ? 0.4 : 1.0)
                        .gesture(longPressDragGesture(clip: clip, geo: geo))
                        
                        if clips.last?.id != clip.id {
                            Rectangle()
                                .frame(width: 2, height: 8)
                                .foregroundStyle(SnappieColor.primaryLight)
                        }
                    }
                    
                    Button(action: onAddClipTapped) {
                        Image("union")
                            .padding(.horizontal, 16)
                            .frame(height: timelineHeight)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(SnappieColor.primaryLight)
                            )
                    }
                    .padding(.leading, 2)
                }
                .padding(.horizontal, geo.size.width / 2)
                .offset(x: -CGFloat(playHeadPosition) * pxPerSecond + dragOffset)
                .frame(
                    width: geo.size.width + CGFloat(totalDuration) * pxPerSecond,
                    height: timelineHeight,
                    alignment: .leading
                )
                .clipped()

                // Layer 2: The overlay for the currently dragged clip
                if let draggingClip = draggingClip, isDragActive, let dragValue = self.dragValue {
                    let clipWidth = draggingClip.trimmedDuration * pxPerSecond
                    let fingerPosX = dragValue.location.x - geo.frame(in: .global).minX
                    let offsetX = fingerPosX - (clipWidth / 2)

                    ClipTrimmingView(
                        clip: draggingClip,
                        isDragging: .constant(true),
                        onToggleTrimming: { },
                        onTrimChanged: { _, _ in }
                    )
                    .frame(width: clipWidth)
                    .offset(x: offsetX)
                    .scaleEffect(1.1)
                    .shadow(radius: 10)
                }
            }
        }
        .frame(height: timelineHeight)
    }

    // MARK: - Drag & Drop Gesture
    private func longPressDragGesture(clip: EditableClip, geo: GeometryProxy) -> some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in
                withAnimation(.spring()) {
                    draggingClip = clip
                    isDragActive = true
                }
            }
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .global))
            .onChanged { value in
                guard case .second(true, let drag) = value else { return }
                self.dragValue = drag
            }
            .onEnded { value in
                if case .second(true, let drag) = value, let drag = drag, let sourceIndex = clips.firstIndex(where: { $0.id == draggingClip?.id }) {
                    let timelineFrame = geo.frame(in: .global)
                    let timelineContentOffset = -CGFloat(playHeadPosition) * pxPerSecond + dragOffset
                    let contentStartGlobalX = timelineFrame.minX + (timelineFrame.width / 2) + timelineContentOffset
                    let relativeDropX = drag.location.x - contentStartGlobalX
                    
                    let destinationIndex = getDestinationIndex(relativeDropX: relativeDropX, sourceIndex: sourceIndex)
                    
                    onMove(IndexSet(integer: sourceIndex), destinationIndex)
                }
                
                withAnimation(.spring()) {
                    draggingClip = nil
                    dragValue = nil
                    isDragActive = false
                }
            }
    }
    
    private func getDestinationIndex(relativeDropX: CGFloat, sourceIndex: Int) -> Int {
        var accumulatedWidth: CGFloat = 0
        var targetIndex = 0

        for (index, clip) in clips.enumerated() {
            if index == sourceIndex { continue } // Skip the original item
            
            let clipWidth = clip.trimmedDuration * pxPerSecond
            let clipSpacing: CGFloat = (index < clips.count - 1) ? 2 : 0
            
            if relativeDropX < accumulatedWidth + (clipWidth + clipSpacing) / 2 {
                return index > sourceIndex ? index - 1 : index
            }
            accumulatedWidth += clipWidth + clipSpacing
        }
        
        return clips.count - 1
    }
}