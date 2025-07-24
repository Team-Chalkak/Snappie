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

    @State private var scrollOffset: CGFloat = 0.0
    @State private var timelineWidth: CGFloat = 0.0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 시간 표시 (현재 시간 / 전체 길이)
            HStack {
                Text(formattedTime(playHeadPosition))
                    .font(.caption)
                Spacer()
                Text(formattedTime(totalDuration))
                    .font(.caption)
            }

            // 타임라인 클립 썸네일 + 핸들
            GeometryReader { geometry in
                ScrollViewReader { scrollReader in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(clips) { clip in
                                ClipTrimmingView(
                                    clip: clip,
                                    isTrimming: clip.isTrimming,
                                    isDragging: $isDragging,
                                    onToggleTrimming: {
                                        onToggleTrimming(clip.id)
                                    },
                                    onTrimChanged: { newStart, newEnd in
                                        onTrimChanged(clip.id, newStart, newEnd)
                                    }
                                )
                            }
                            // dummy ID
                            Color.clear
                                .frame(width: 1, height: 1)
                                .id("scroll-target")
                        }
                        .background(GeometryReader {
                            Color.clear.preference(key: TimelineWidthKey.self, value: $0.size.width)
                        })
                        .onPreferenceChange(TimelineWidthKey.self) { width in
                            timelineWidth = width
                        }
                    }
                    .overlay(alignment: .center) {
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 2, height: 60)
                    }
                    .onChange(of: playHeadPosition) { newTime in
                        scrollToPlayhead(reader: scrollReader, container: geometry.size)
                    }
                }
            }
            .frame(height: 80)
        }
    }

    // MARK: - 시간 포맷 함수
    private func formattedTime(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // MARK: - 재생 중 자동 스크롤
    private func scrollToPlayhead(reader: ScrollViewProxy, container: CGSize) {
        let relativeX = CGFloat(playHeadPosition / totalDuration) * timelineWidth
        let scrollX = max(0, relativeX - container.width / 2)
        withAnimation {
            reader.scrollTo("playhead-scroll", anchor: .leading)
        }
    }
}


private struct TimelineWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
