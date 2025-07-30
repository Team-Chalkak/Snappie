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
    @StateObject private var viewModel: ProjectEditViewModel
    @EnvironmentObject private var coordinator: Coordinator
    @State private var showExitConfirmation = false
    @State private var showExportSuccessAlert = false
    @State private var isExporting = false
    
    init(projectID: String) {
        self._viewModel = StateObject(wrappedValue: ProjectEditViewModel(projectID: projectID))
    }

    var body: some View {
        VStack(spacing: 0) {
            SnappieNavigationBar(
                navigationTitle: "프로젝트 편집",
                leftButtonType: .backward {
                    showExitConfirmation = true
                },
                rightButtonType: .oneButton(.init(label: "내보내기") {
                    Task {
                        await viewModel.exportEditedVideoToPhotos()
                        showExportSuccessAlert = true
                    }
                })
            )
            .padding(.bottom, 16)
            
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
            
            // 재생 일시정지 버튼 & 시간표시하는 서브뷰
            PlayInfoView(
                isPlaying: $viewModel.isPlaying,
                onPlayPauseTapped: viewModel.togglePlayback,
                currentTime: viewModel.playHead,
                totalDuration: viewModel.totalDuration,
                trimmingClip: viewModel.editableClips.first(where: { $0.isTrimming })
            )
            .padding(.vertical, 16)
            
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
        .background(
            SnappieColor.darkHeavy
                .ignoresSafeArea()
        )
        // 뒤로가기 확인 다이얼로그
        .confirmationDialog(
            "편집된 내용을 저장할까요? 저장하지 않으면 편집 내용이 사라집니다.",
            isPresented: $showExitConfirmation,
            titleVisibility: .visible
        ) {
            Button("저장하기") {
                viewModel.saveProjectChanges()
                coordinator.popLast()
            }
            Button("저장하지 않고 나가기", role: .destructive) {
                coordinator.popLast()
            }
            Button("취소", role: .cancel) {}
        }
        // 내보내기 완료 알림
        .snappieAlert(
            isPresented: $showExportSuccessAlert,
            message: "내보내기 완료"
        )
        // 진행중 로딩 프로그레스
        .snappieProgressAlert(
            isPresented: $isExporting,
            isLoading: $isExporting,
            loadingMessage: "영상 내보내는 중...",
            completionMessage: ""
        )
    }
}
