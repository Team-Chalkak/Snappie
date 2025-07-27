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
    private let rulerHeight: CGFloat = 20

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let halfW = geo.size.width / 2
            VStack(spacing: 0) {
                // 1) 시간 눈금 (ruler)
                HStack(spacing: 0) {
                    ForEach(0...Int(totalDuration), id: \.self) { sec in
                        VStack(spacing: 2) {
                            if sec % 2 == 1 {
                                Text("\(sec)")
                                    .font(.caption2)
                            } else {
                                Circle()
                                    .frame(width: 2, height: 2)
                            }
                            Spacer()
                        }
                        .frame(width: pxPerSecond, height: rulerHeight)
                    }
                }
                .padding(.horizontal, halfW)
                .offset(x: -CGFloat(playHeadPosition) * pxPerSecond + dragOffset)
                .frame(
                    width: geo.size.width + CGFloat(totalDuration) * pxPerSecond,
                    height: rulerHeight,
                    alignment: .leading
                )

                // 2) 클립 타임라인 + + 버튼
                ZStack(alignment: .leading) {
                    HStack(spacing: clipSpacing) {
                        ForEach(clips) { clip in
                            ClipTrimmingView(
                                clip: clip,
                                isDragging: $isDragging,
                                onToggleTrimming: { onToggleTrimming(clip.id) },
                                onTrimChanged:   { s,e in onTrimChanged(clip.id, s, e) }
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
                    .offset(x: -CGFloat(playHeadPosition) * pxPerSecond + dragOffset)
                    .frame(
                        width: geo.size.width + CGFloat(totalDuration) * pxPerSecond,
                        height: timelineHeight,
                        alignment: .leading
                    )
                    .clipped()
                    // 드래그 제스처는 타임라인 전체에 적용
                    .gesture(
                        DragGesture()
                            .onChanged { g in
                                isDragging = true
                                dragOffset = g.translation.width
                            }
                            .onEnded { g in
                                isDragging = false
                                // 이동량 → 시간으로 변환
                                let deltaTime = -Double(g.translation.width / pxPerSecond)
                                var newTime = playHeadPosition + deltaTime
                                newTime = min(max(0, newTime), totalDuration)
                                onSeek(newTime)
                                dragOffset = 0
                            }
                    )

                    // 3) 중앙 고정 플레이헤드
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 2, height: timelineHeight + rulerHeight)
                        .position(x: halfW, y: (timelineHeight + rulerHeight)/2)
                }
            }
        }
        .frame(height: timelineHeight + rulerHeight)
    }
}
