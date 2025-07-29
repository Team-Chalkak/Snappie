//
//  ProjectEditView.swift
//  Chalkak
//
//  Created by 배현진 on 7/24/25.
//

import SwiftUI
import AVKit

/// 프로젝트 편집 메인뷰
struct ProjectEditView: View {
    @StateObject private var viewModel = ProjectEditViewModel()
    @EnvironmentObject private var coordinator: Coordinator

    var body: some View {
        VStack(spacing: 0) {
            SnappieNavigationBar(
                navigationTitle: "프로젝트 편집",
                leftButtonType: .backward {
                    // TODO: confirmation dialog 띄우기(ssol)
                },
                rightButtonType: .oneButton(.init(label: "내보내기") {
                    // TODO: 영상 저장 로직(ssol)
                })
            )
            .padding(.bottom, 16)
            .padding(.horizontal, -16)

            ZStack {
                VideoPreviewView(
                    previewImage: viewModel.previewImage,
                    player: viewModel.player,
                    isDragging: viewModel.isDragging
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // 선택된 클립이 있을 때만 Delete 버튼 표시
                if let trimmingClip = viewModel.editableClips.first(where: { $0.isTrimming }) {
                    VStack {
                        Spacer()
                        Button(action: {
                            viewModel.deleteClip(id: trimmingClip.id)
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(SnappieColor.redRecording)
                                .padding(8)
                                .frame(width: 40, height: 40, alignment: .center)
                                .background(SnappieColor.containerFillNormal)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.bottom, 16)
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
