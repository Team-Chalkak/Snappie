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

    @State private var timelineWidth: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // ─── 시간 표시 ──────────────────
            HStack {
                Text(formattedTime(playHeadPosition)).font(.caption)
                Spacer()
                Text(formattedTime(totalDuration)).font(.caption)
            }

            // ─── 스크롤 & 플레이헤드 ──────────
            GeometryReader { geo in
                let containerW = geo.size.width

                ScrollViewReader { reader in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(clips) { clip in
                                ClipTrimmingView(
                                    clip: clip,
                                    isTrimming: clip.isTrimming,
                                    isDragging: $isDragging,
                                    onToggleTrimming: { onToggleTrimming(clip.id) },
                                    onTrimChanged: { s, e in onTrimChanged(clip.id, s, e) }
                                )
                                .frame(width: clipWidth(for: clip), height: 60)
                            }

                            // 플레이헤드 위치에 맞춘 dummy 뷰
                            Color.clear
                                .frame(width: 1, height: 1)
                                .id("scroll-target")
                                .offset(x: relativeX(in: timelineWidth))
                        }
                        .background(GeometryReader {
                            Color.clear
                                .preference(key: TimelineWidthKey.self, value: $0.size.width)
                        })
                    }
                    // 플레이헤드
                    .overlay(alignment: .center) {
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 2, height: 60)
                    }
                    // 전체 타임라인 너비 파악
                    .onPreferenceChange(TimelineWidthKey.self) { timelineWidth = $0 }
                    // 플레이헤드 이동 시 자동 스크롤
                    .onChange(of: playHeadPosition) { _ in
                        withAnimation { reader.scrollTo("scroll-target", anchor: .center) }
                    }
                }
            }
            .frame(height: 60)
        }
    }

    // MARK: - 헬퍼
    private func formattedTime(_ sec: Double) -> String {
        let t = Int(sec)
        return "\(t/60):\(String(format: "%02d", t%60))"
    }

    private func relativeX(in totalW: CGFloat) -> CGFloat {
        guard totalDuration > 0 else { return 0 }
        let ratio = CGFloat(playHeadPosition / totalDuration)
        return ratio * totalW
    }

    private func clipWidth(for clip: EditableClip) -> CGFloat {
        // 예: 화면 너비 기준 비율
        let screenW = UIScreen.main.bounds.width - 32
        return screenW * CGFloat(clip.trimmedDuration / totalDuration)
    }
}

private struct TimelineWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
