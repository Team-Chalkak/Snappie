//
//  ProjectEditView.swift
//  Chalkak
//
//  Created by 배현진 on 7/24/25.
//

import SwiftUI
import AVKit

struct ProjectEditView: View {
    @StateObject private var viewModel = ProjectEditViewModel()

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 16)

            // 프리뷰 영상
            VideoPreviewView(
                previewImage: viewModel.previewImage,
                player: viewModel.player,
                isDragging: viewModel.isDragging,
                overlayImage: nil
            )

            Divider().padding(.vertical, 8)

            // 타임라인 및 시간 표시P
            TrimminglineSliderView(
                clips: $viewModel.editableClips,
                playHeadPosition: $viewModel.playHead,
                isDragging: $viewModel.isDragging,
                isPlaying: viewModel.isPlaying,
                totalDuration: viewModel.totalDuration,
                onSeek: viewModel.seekTo,
                onToggleTrimming: viewModel.toggleTrimmingMode,
                onTrimChanged: viewModel.updateTrimRange
            )

            Divider()

            // 재생 컨트롤
            PlayButtonControlView(
                isPlaying: $viewModel.isPlaying,
                onPlayPauseTapped: viewModel.togglePlayback
            )
        }
        .padding(.horizontal, 16)
        .onAppear {
            viewModel.loadProject()
        }
        .navigationTitle("프로젝트 트리밍")
        .navigationBarTitleDisplayMode(.inline)
    }
}
