//
//  TrimmingLineView.swift
//  Chalkak
//
//  Created by Youbin on 7/14/25.
//

import SwiftUI
import AVKit

struct TrimmingLineView: View {
    @ObservedObject var viewModel: ClipEditViewModel
    
    var body: some View {
        VStack(alignment: .center, spacing: 0, content: {

            TimeDisplay()
            
            TimeLine
            
        })
        .background(Color.gray)
    }
    
    //MARK: 재생 버튼 + 트리밍 라인
    private var TimeLine: some View {
        HStack(alignment: .center, spacing: 15, content: {
            Button(action: {
                viewModel.togglePlayback()
            }) {
                Image(viewModel.isPlaying ? "pauseBtn" : "playBtn")
                    .frame(width: 36, height: 36)
                    .foregroundColor(.black)
            }
            
            trimmingLine
                .frame(height: 60)
        })
        .frame(height: 128)
        .padding(.horizontal, 16)
    }
    
    //MARK: 트리밍 라인만
    private var trimmingLine: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let thumbnailCount = viewModel.thumbnails.count
            let thumbnailWidth = totalWidth / CGFloat(thumbnailCount)
            let startX = CGFloat(viewModel.startPoint / viewModel.duration) * totalWidth
            let endX = CGFloat(viewModel.endPoint / viewModel.duration) * totalWidth
            let trimmingWidth = endX - startX

            ZStack(alignment: .leading) {
                /// 1. 썸네일들
                HStack(spacing: 0) {
                    ForEach(viewModel.thumbnails, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: thumbnailWidth, height: 60)
                            .clipped()
                    }
                }

                /// 2. 잘린 영역 어둡게 처리
                HStack(spacing: 0) {
                    Rectangle() // 왼쪽 어두운 영역
                        .fill(Color.black.opacity(0.5))
                        .frame(width: startX)

                    Rectangle() // 선택된 밝은 영역 (투명)
                        .fill(Color.clear)
                        .frame(width: trimmingWidth)

                    Rectangle() // 오른쪽 어두운 영역
                        .fill(Color.black.opacity(0.5))
                    // 나머지 공간 자동으로 채움
                }

                /// 3. 트리밍 테두리
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.yellow, lineWidth: 2)
                    .frame(width: trimmingWidth, height: 60)
                    .position(x: startX + trimmingWidth / 2, y: 30)

                /// 4. 트리밍 핸들
                Group {
                    handleView()
                        .position(x: startX, y: 30)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    viewModel.player?.pause()
                                    viewModel.isPlaying = false
                                    let newStart = max(
                                        0,
                                        min(gesture.location.x / totalWidth * viewModel.duration,
                                            viewModel.endPoint - 0.1)
                                    )
                                    viewModel.updateStart(newStart)
                                }
                                .onEnded { _ in
                                    viewModel.playPreview()
                                }
                        )

                    handleView()
                        .position(x: endX, y: 30)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    viewModel.player?.pause()
                                    viewModel.isPlaying = false
                                    let newEnd = min(
                                        viewModel.duration,
                                        max(gesture.location.x / totalWidth * viewModel.duration,
                                            viewModel.startPoint + 0.1)
                                    )
                                    viewModel.updateEnd(newEnd)
                                }
                                .onEnded { _ in
                                    viewModel.playPreview()
                                }
                    )
                }
                
                /// 5. 시작 지점 미리보기 테두리
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 34, height: 57)
                    .position(x: startX + 20, y: 30)
                
            }
        }
    }
    
    //MARK: handle 재사용
    private func handleView() -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.yellow)
            .frame(width: 10, height: 60)
    }
}

#Preview {
    ClipEditView()
}
