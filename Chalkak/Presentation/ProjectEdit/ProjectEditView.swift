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
    @EnvironmentObject private var coordinator: Coordinator

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 16)

            ZStack {
                VideoPreviewView(
                    previewImage: viewModel.previewImage,
                    player: viewModel.player,
                    isDragging: viewModel.isDragging,
                    overlayImage: nil
                )
                
                // 선택된 클립이 있을 때만 Delete 버튼 표시
                if let trimmingClip = viewModel.editableClips.first(where: { $0.isTrimming }) {
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.deleteClip(id: trimmingClip.id)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .imageScale(.large)
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.bottom, 8)
                }
            }

            PlayButtonControlView(
                isPlaying: $viewModel.isPlaying,
                onPlayPauseTapped: viewModel.togglePlayback
            )
            
            PlayTimeView(
                currentTime: viewModel.playHead,
                totalDuration: viewModel.totalDuration,
                trimmingClip: viewModel.editableClips.first(where: { $0.isTrimming })
            )
            
            Divider().padding(.vertical, 8)

            TrimminglineSliderView(
                clips: $viewModel.editableClips,
                playHeadPosition: $viewModel.playHead,
                isDragging: $viewModel.isDragging,
                isPlaying: viewModel.isPlaying,
                totalDuration: viewModel.totalDuration,
                onSeek: viewModel.seekTo,
                onToggleTrimming: viewModel.toggleTrimmingMode,
                onTrimChanged: viewModel.updateTrimRange,
                onAddClipTapped: {
                    coordinator.push(.boundingBox(guide: viewModel.guide ?? nil))
                }
            )
        }
        .padding(.horizontal, 16)
        .onAppear { viewModel.loadProject() }
        .navigationTitle("프로젝트 트리밍")
        .navigationBarTitleDisplayMode(.inline)
    }
}
