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
    let onAddClipTapped: () -> Void

    private let pxPerSecond: CGFloat = 50
    private let clipSpacing: CGFloat = 8
    private let timelineHeight: CGFloat = 60

    // 드래그 오프셋 상태
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let halfW = geo.size.width / 2

            ZStack(alignment: .leading) {
                HStack(spacing: clipSpacing) {
                    ForEach(clips) { clip in
                        ClipTrimmingView(
                            clip: clip,
                            isDragging: $isDragging,
                            onToggleTrimming: { onToggleTrimming(clip.id) },
                            onTrimChanged:   { s, e in onTrimChanged(clip.id, s, e) }
                        )
                    }
                    // + 버튼
                    Button(action: onAddClipTapped) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.gray, lineWidth: 1)
                                .frame(width: timelineHeight, height: timelineHeight)
                            Image(systemName: "plus")
                                .font(.title2)
                        }
                    }
                    .frame(width: timelineHeight, height: timelineHeight)
                }
                .padding(.horizontal, halfW)
                // 드래그 오프셋과 플레이헤드 기반 오프셋 합산
                .offset(x: -CGFloat(playHeadPosition) * pxPerSecond + dragOffset)
                .frame(
                    width: geo.size.width + CGFloat(totalDuration) * pxPerSecond,
                    height: timelineHeight,
                    alignment: .leading
                )
                .clipped()
                // 드래그 제스처
                .gesture(
                    DragGesture()
                        .onChanged { g in
                            isDragging = true
                            dragOffset = g.translation.width
                        }
                        .onEnded { g in
                            isDragging = false
                            // 드래그로 바뀐 시간량 계산 (음수 드래그는 앞으로, 양수는 뒤로)
                            let deltaTime = -Double(g.translation.width / pxPerSecond)
                            var newTime = playHeadPosition + deltaTime
                            newTime = min(max(0, newTime), totalDuration)
                            // 플레이헤드 이동 & 프리뷰 갱신
                            onSeek(newTime)
                            // 드래그 오프셋 초기화
                            dragOffset = 0
                        }
                )

                // 중앙 고정 플레이헤드
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 2, height: timelineHeight)
                    .position(x: halfW, y: timelineHeight/2)
            }
        }
        .frame(height: timelineHeight)
    }
}
