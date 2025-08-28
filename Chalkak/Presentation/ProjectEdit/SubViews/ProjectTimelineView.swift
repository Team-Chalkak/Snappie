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

    // 실시간 삽입 후보 위치(갭 인덱스)
    @State private var insertionIndex: Int?
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Layer 1: The scrollable timeline
                HStack(alignment: .center, spacing: 0) {
                    ForEach(Array(clips.enumerated()), id: \.1.id) { index, clip in
                        let isBeingDragged = (draggingClip?.id == clip.id && isDragActive)
                        let clipWidth = clip.trimmedDuration * pxPerSecond
                        let draggingWidth = (draggingClip?.trimmedDuration ?? 0) * pxPerSecond

                        // 후보 삽입 지점이면 갭(placeholder) 먼저 삽입
                        if let insertionIndex, insertionIndex == index, isDragActive, draggingWidth > 0 {
                            insertionGap(width: draggingWidth)
                        }
                        
                        ClipTrimmingView(
                            clip: clip,
                            isDragging: $isDragging,
                            onToggleTrimming: { onToggleTrimming(clip.id) },
                            onTrimChanged: { s, e in onTrimChanged(clip.id, s, e) }
                        )
                        .frame(width: isBeingDragged ? 0.0 : clipWidth, height: timelineHeight)
                        .opacity(isBeingDragged ? 0.0 : 1.0)
                        .animation(.interactiveSpring(response: 0.22, dampingFraction: 0.88), value: insertionIndex)
                        .gesture(longPressDragGesture(clip: clip, geo: geo))
                        
                        if clips.last?.id != clip.id {
                            Rectangle()
                                .frame(width: 2, height: 8)
                                .foregroundStyle(SnappieColor.primaryLight)
                        }
                    }
                    
                    // 리스트 끝에 삽입하는 경우(맨 뒤)
                    if let insertionIndex,
                       insertionIndex == clips.count,
                       isDragActive,
                       let draggingClip
                    {
                        insertionGap(width: draggingClip.trimmedDuration * pxPerSecond)
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
                    .scaleEffect(1.2)
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
                guard case .second(true, let drag) = value,
                          let drag = drag else { return }
                self.dragValue = drag
                
                // 실시간 삽입 후보 계산
                if let sourceIndex = clips.firstIndex(where: { $0.id == draggingClip?.id }) {
                    let timelineFrame = geo.frame(in: .global)
                    let timelineContentOffset = -CGFloat(playHeadPosition) * pxPerSecond + dragOffset
                    let contentStartGlobalX = timelineFrame.minX + (timelineFrame.width / 2) + timelineContentOffset
                    let relativeDropX = drag.location.x - contentStartGlobalX

                    let candidate = getDestinationIndex(relativeDropX: relativeDropX, sourceIndex: sourceIndex)
                    if insertionIndex != candidate {
                        withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.88)) {
                            insertionIndex = candidate
                        }
                    }
                }
            }
            .onEnded { value in
                defer {
                    withAnimation(.spring()) {
                        draggingClip = nil
                        dragValue = nil
                        isDragActive = false
                        insertionIndex = nil
                    }
                }

                guard case .second(true, let drag) = value,
                      let drag = drag,
                      let sourceIndex = clips.firstIndex(where: { $0.id == draggingClip?.id })
                else { return }

                let timelineFrame = geo.frame(in: .global)
                let timelineContentOffset = -CGFloat(playHeadPosition) * pxPerSecond + dragOffset
                let contentStartGlobalX = timelineFrame.minX + (timelineFrame.width / 2) + timelineContentOffset
                let relativeDropX = drag.location.x - contentStartGlobalX

                let destinationIndex = getDestinationIndex(relativeDropX: relativeDropX, sourceIndex: sourceIndex)
                onMove(IndexSet(integer: sourceIndex), destinationIndex)
            }
    }
    
    private func getDestinationIndex(relativeDropX: CGFloat, sourceIndex: Int) -> Int {
        var accumulatedWidth: CGFloat = 0
        var candidate = clips.count - 1

        for (index, clip) in clips.enumerated() {
            if index == sourceIndex { continue }
            
            let clipWidth = clip.trimmedDuration * pxPerSecond
            let clipSpacing: CGFloat = (index < clips.count - 1) ? 2 : 0
            
            if relativeDropX < accumulatedWidth + (clipWidth + clipSpacing) / 2 {
                candidate = index
                break
            }
            accumulatedWidth += clipWidth + clipSpacing
        }
        // SwiftUI onMove 규칙: 뒤에서 앞으로/앞에서 뒤로 이동할 때 인덱스 보정
        return candidate > sourceIndex ? candidate - 1 : candidate
    }
    
    // MARK: - 갭(placeholder) 뷰
   @ViewBuilder
   private func insertionGap(width: CGFloat) -> some View {
       RoundedRectangle(cornerRadius: 6)
           .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
           .foregroundStyle(SnappieColor.primaryLight)
           .frame(width: max(4, width), height: timelineHeight)
           .transition(.opacity.combined(with: .move(edge: .leading)))
           .animation(.easeInOut(duration: 0.18), value: insertionIndex)
   }
}
