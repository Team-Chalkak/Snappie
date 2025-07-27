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

            VideoPreviewView(
                previewImage: viewModel.previewImage,
                player: viewModel.player,
                isDragging: viewModel.isDragging,
                overlayImage: nil
            )
            .frame(maxWidth: .infinity, maxHeight: 300)

            Divider().padding(.vertical, 8)

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

            PlayButtonControlView(
                isPlaying: $viewModel.isPlaying,
                onPlayPauseTapped: viewModel.togglePlayback
            )
        }
        .padding(.horizontal, 16)
        .onAppear { viewModel.loadProject() }
        .navigationTitle("프로젝트 트리밍")
        .navigationBarTitleDisplayMode(.inline)
    }
}
