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
    let onDragStateChanged: (Bool) -> Void
    
    private let unionButtonWidth: CGFloat = 48

    // 드래그 상태
    @State private var draggingClip: EditableClip?
    @State private var dragValue: DragGesture.Value?
    @State private var isDragActive = false

    // 삽입 후보 인덱스(gap)
    @State private var insertionIndex: Int?

    // 드래그 앵커(손가락이 클립 내부에서 찍힌 상대 X)
    @State private var dragAnchorInClip: CGFloat?

    var body: some View {
        GeometryReader { geo in
            let halfWidth = geo.size.width / 2
            
            ZStack(alignment: .leading) {
                // Layer 1: timeline content
                HStack(alignment: .center, spacing: 0) {
                    ForEach(Array(clips.enumerated()), id: \.1.id) { index, clip in
                        let isBeingDragged = (draggingClip?.id == clip.id && isDragActive)
                        let clipWidth = clip.trimmedDuration * pxPerSecond
                        let draggingWidth = (draggingClip?.trimmedDuration ?? 0) * pxPerSecond

                        // gap
                        if let insertionIndex, insertionIndex == index, isDragActive, draggingWidth > 0 {
                            insertionGap(width: draggingWidth)
                        }

                        // 드래그 중 원본은 숨김(겹침 방지)
                        ClipTrimmingView(
                            clip: clip,
                            isDragging: $isDragging,
                            onToggleTrimming: { onToggleTrimming(clip.id) },
                            onTrimChanged: { s, e in onTrimChanged(clip.id, s, e) },
                            onDragStateChanged: onDragStateChanged
                        )
                        .frame(width: isBeingDragged ? 0.0 : clipWidth, height: timelineHeight)
                        .opacity(isBeingDragged ? 0.0 : 1.0)
                        .animation(.interactiveSpring(response: 0.22, dampingFraction: 0.88), value: insertionIndex)
                        .gesture(longPressDragGesture(clip: clip, geo: geo))
                    }

                    // 맨 뒤 삽입
                    if let insertionIndex,
                       insertionIndex == clips.count,
                       isDragActive,
                       let draggingClip {
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

                // Layer 2: overlay (앵커 기반 왼쪽 정렬)
                if let draggingClip = draggingClip, isDragActive, let dragValue = self.dragValue {
                    let clipWidth = draggingClip.trimmedDuration * pxPerSecond
                    let viewMinX = geo.frame(in: .global).minX

                    // 손가락이 누른 위치(클립 내부 상대 X). 없으면 가운데로.
                    let anchorX: CGFloat = dragAnchorInClip ?? (clipWidth / 2)

                    // 스케일을 적용할 크기
                    let scaleDuringDrag: CGFloat = 1.2

                    // 스케일 없음 기준의 "왼쪽" 오프셋(로컬)
                    let baseOffsetX = (dragValue.location.x - viewMinX) - anchorX

                    // 스케일 보정: (1 - s) * (anchor - center)
                    let centerX = clipWidth / 2
                    let scaleCompensation = (1 - scaleDuringDrag) * (anchorX - centerX)

                    let adjustedOffsetX = baseOffsetX + scaleCompensation

                    ClipTrimmingView(
                        clip: draggingClip,
                        isDragging: .constant(true),
                        onToggleTrimming: { },
                        onTrimChanged: { _, _ in },
                        onDragStateChanged: onDragStateChanged
                    )
                    .frame(width: clipWidth)
                    .scaleEffect(scaleDuringDrag, anchor: .center)
                    .offset(x: adjustedOffsetX)
                    .shadow(radius: 10)
                }
            }
            .padding(.horizontal, halfWidth)
            .offset(x: -CGFloat(playHeadPosition) * pxPerSecond + dragOffset)
            .frame(
                width: getTimelineFullWidth(geoWidth: geo.size.width),
                height: timelineHeight,
                alignment: .leading
            )
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
                guard case .second(true, let maybeDrag) = value,
                      let drag = maybeDrag else { return }
                self.dragValue = drag

                guard let draggingClip = draggingClip,
                      let sourceIndex = clips.firstIndex(where: { $0.id == draggingClip.id }) else { return }

                // 드래그 시작 시 1회 앵커 계산: (손가락 전역X) - (클립 전역 왼쪽X)
                if dragAnchorInClip == nil {
                    let timelineFrame = geo.frame(in: .global)
                    let timelineOffset = -CGFloat(playHeadPosition) * pxPerSecond + dragOffset
                    let contentStartGlobalX = timelineFrame.minX + (timelineFrame.width / 2) + timelineOffset

                    // HStack 내에서 해당 클립의 왼쪽X(콘텐츠 좌표) 합산
                    var leadingXInContent: CGFloat = 0
                    for (index, clip) in clips.enumerated() {
                        if clip.id == draggingClip.id { break }
                        leadingXInContent += clip.trimmedDuration * pxPerSecond
                        if index < clips.count - 1 { leadingXInContent += clipSpacing }
                    }
                    let clipLeftGlobalX = contentStartGlobalX + leadingXInContent

                    let clipWidth = draggingClip.trimmedDuration * pxPerSecond
                    var anchor = drag.location.x - clipLeftGlobalX
                    anchor = max(0, min(anchor, clipWidth))      // 0...clipWidth 로 클램프
                    dragAnchorInClip = anchor
                }

                // 현재 왼쪽X(콘텐츠 좌표) = 손가락X(전역) - contentStart(전역) - 앵커
                let contentStart = contentStartGlobalX(geo)
                let leftX = (drag.location.x - contentStart) - (dragAnchorInClip ?? 0)

                // UI용 gap 인덱스(보정 없음)
                let candidate = computeInsertionIndex(leftX: leftX, sourceIndex: sourceIndex)
                if insertionIndex != candidate {
                    withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.88)) {
                        insertionIndex = candidate
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
                        dragAnchorInClip = nil
                    }
                }

                guard case .second(true, let maybeDrag) = value,
                      let drag = maybeDrag,
                      let draggingClip = draggingClip,
                      let sourceIndex = clips.firstIndex(where: { $0.id == draggingClip.id }) else { return }

                let contentStart = contentStartGlobalX(geo)
                let leftX = (drag.location.x - contentStart) - (dragAnchorInClip ?? 0)

                let rawInsertion = insertionIndex ?? computeInsertionIndex(leftX: leftX, sourceIndex: sourceIndex)

                onMove(IndexSet(integer: sourceIndex), rawInsertion)
            }
    }

    // MARK: - Helpers (좌표/인덱스 계산)
    /// 타임라인뷰의 글로벌 좌표 기준 시작지점 X를 계산합니다.
    /// - Parameter geo: `GeometryReader`가 넘겨주는 현재 뷰의 지오메트리.
    /// - Returns: 글로벌 좌표계에서 타임라인 콘텐츠의 선두(leading) X 값.
    private func contentStartGlobalX(_ geo: GeometryProxy) -> CGFloat {
        let frame = geo.frame(in: .global)
        let halfWidth = frame.size.width / 2
        let timelineOffset = -CGFloat(playHeadPosition) * pxPerSecond + dragOffset
        return frame.minX + halfWidth + timelineOffset
    }

    /// 타임라인 내부에서 특정 클립의 왼쪽 모서리 X를 계산합니다.
    /// - Parameter clipID: 위치를 구할 클립의 식별자.
    /// - Returns: 콘텐츠 좌표계에서 해당 클립 leading X.
    private func leftXOfClipInContent(_ clipID: String) -> CGFloat {
        var accumulatedX: CGFloat = 0
        for (index, clip) in clips.enumerated() {
            if clip.id == clipID { break }
            accumulatedX += clip.trimmedDuration * pxPerSecond
            if index < clips.count - 1 { accumulatedX += 2 } // 구분선 폭과 동일하게
        }
        return accumulatedX
    }
    
    /// 드래그 중인 클립의 왼쪽 모서리 X(콘텐츠 좌표계 기준) 를 바탕으로,
    /// 현재 배열에서 어느 인덱스 앞에 삽입할지(갭 인덱스)를 계산합니다.
    /// - Parameters:
    ///   - leftX: 드래그 중인 클립의 leading X (콘텐츠 좌표계).
    ///            일반적으로 `fingerGlobalX - contentStartGlobalX - dragAnchorWithinClip`.
    ///   - sourceIndex: 드래그 중인 클립의 원본 배열 인덱스(자기 폭 제외 용도).
    /// - Returns: 삽입할 갭 인덱스(0...`clips.count`). `clips.count`면 맨 뒤.
    private func computeInsertionIndex(leftX: CGFloat, sourceIndex: Int) -> Int {
        var accumulatedX: CGFloat = 0
        var reducedIdx = 0
        let reducedCount = clips.count - 1
        
        for (index, clip) in clips.enumerated() {
            if index == sourceIndex { continue }
            let clipWidth = clip.trimmedDuration * pxPerSecond
            let spacingAfter: CGFloat = (reducedIdx < reducedCount - 1) ? clipSpacing : 0
            let boundaryMidX = accumulatedX + (clipWidth + spacingAfter) / 2
            if leftX < boundaryMidX { return index }
            accumulatedX += clipWidth + spacingAfter
            reducedIdx += 1
        }
        return clips.count
    }

    // MARK: - gap 뷰
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

extension ProjectTimelineView {
    func getTimelineFullWidth(geoWidth: CGFloat) -> CGFloat {
        let videoRangeWidth = CGFloat(totalDuration) * pxPerSecond
        
        return geoWidth + videoRangeWidth + unionButtonWidth
    }
}
