//
//  ClipTrimmingView.swift
//  Chalkak
//
//  Created by 배현진 on 7/24/25.
//

import SwiftUI
import AVFoundation

struct ClipTrimmingView: View {
    let clip: EditableClip
    let isTrimming: Bool
    let isDragging: Binding<Bool>
    let onToggleTrimming: () -> Void
    let onTrimChanged: (_ newStart: Double, _ newEnd: Double) -> Void

    @State private var thumbnails: [UIImage] = []
    @State private var width: CGFloat = 160

    private let thumbnailCount = 10
    private let thumbnailHeight: CGFloat = 60

    var body: some View {
        ZStack(alignment: .leading) {
            // 썸네일
            HStack(spacing: 0) {
                ForEach(thumbnails.indices, id: \.self) { index in
                    Image(uiImage: thumbnails[index])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: thumbnailWidth, height: thumbnailHeight)
                        .clipped()
                }
            }

            // 트리밍 어두운 영역
            if isTrimming {
                let leftRatio = clip.startPoint / clip.originalDuration
                let rightRatio = 1 - (clip.endPoint / clip.originalDuration)

                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: width * leftRatio)

                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: width * (1 - leftRatio - rightRatio))

                    Rectangle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: width * rightRatio)
                }

                // 트리밍 박스 테두리
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.yellow, lineWidth: 2)
                    .frame(
                        width: width * (clip.endPoint - clip.startPoint) / clip.originalDuration,
                        height: thumbnailHeight
                    )
                    .offset(x: width * clip.startPoint / clip.originalDuration)

                // 핸들 제스처
                handle(at: .leading)
                handle(at: .trailing)
            }
        }
        .frame(width: width, height: thumbnailHeight)
        .onAppear {
            generateThumbnails()
        }
        .contentShape(Rectangle()) // 탭 인식
        .onTapGesture {
            onToggleTrimming()
        }
    }

    // MARK: - 핸들
    @ViewBuilder
    private func handle(at edge: HorizontalAlignment) -> some View {
        let isStart = edge == .leading
        let handleSize: CGFloat = 10
        let offsetX = isStart
            ? width * clip.startPoint / clip.originalDuration
            : width * clip.endPoint / clip.originalDuration - handleSize

        RoundedRectangle(cornerRadius: 3)
            .fill(Color.yellow)
            .frame(width: handleSize, height: thumbnailHeight)
            .offset(x: offsetX)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        isDragging.wrappedValue = true
                        let ratio = max(0, min(gesture.location.x / width, 1))
                        let time = ratio * clip.originalDuration

                        if isStart {
                            let newStart = min(time, clip.endPoint - 0.1)
                            onTrimChanged(newStart, clip.endPoint)
                        } else {
                            let newEnd = max(time, clip.startPoint + 0.1)
                            onTrimChanged(clip.startPoint, newEnd)
                        }
                    }
                    .onEnded { _ in
                        isDragging.wrappedValue = false  // ✅ 드래그 끝
                    }
            )
    }

    // MARK: - 썸네일 생성
    private func generateThumbnails() {
        let asset = AVAsset(url: clip.url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 100, height: 100)

        let interval = clip.originalDuration / Double(thumbnailCount)
        let times = (0..<thumbnailCount).map {
            NSValue(time: CMTime(seconds: Double($0) * interval, preferredTimescale: 600))
        }

        thumbnails = []
        for time in times {
            if let cgImage = try? generator.copyCGImage(at: time.timeValue, actualTime: nil) {
                thumbnails.append(UIImage(cgImage: cgImage))
            }
        }
    }

    // MARK: - 유틸
    private var thumbnailWidth: CGFloat {
        width / CGFloat(thumbnailCount)
    }
}
