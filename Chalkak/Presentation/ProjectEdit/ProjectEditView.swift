//
//  ProjectEditView.swift
//  Chalkak
//
//  Created by 배현진 on 7/24/25.
//

import AVKit
import SwiftUI

/// 프로젝트 편집 메인뷰
struct ProjectEditView: View {
    @StateObject private var viewModel: ProjectEditViewModel
    @EnvironmentObject private var coordinator: Coordinator
    @State private var showExitConfirmation = false
    @State private var showExportSuccessAlert = false
    @State private var isExporting = false
    
    // appendShoot에서 전달된 클립 데이터
    @State private var newClip: Clip? = nil
    
    init(projectID: String, newClip: Clip? = nil) {
        self._viewModel = StateObject(wrappedValue: ProjectEditViewModel(projectID: projectID))
        self._newClip = State(initialValue: newClip)
    }

    var body: some View {
        ZStack {
            // 배경 탭을 위한 뷰
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.deactivateAllTrimming()
                }
            
            VStack(spacing: 0) {
                SnappieNavigationBar(
                    navigationTitle: "프로젝트 편집",
                    leftButtonType: .backward {
                        if viewModel.hasChanges {
                            showExitConfirmation = true
                        } else {
                            UserDefaults.standard.set(nil, forKey: UserDefaultKey.currentProjectID)
                            coordinator.popToScreen(.projectList)
                        }
                    },
                    rightButtonType: .oneButton(.init(label: "내보내기") {
                        Task {
                            await viewModel.exportEditedVideoToPhotos()
                            showExportSuccessAlert = true
                        }
                    })
                )
                .padding(.bottom, 16)
                
                ProjectPreviewSectionView(viewModel: viewModel)
                
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
                    onMove: viewModel.moveClip,
                    onAddClipTapped: {
                        viewModel.setCurrentProjectID()
                        guard let guide = viewModel.guide else {
                            print("Error: Guide not loaded yet")
                            return
                        }
                        // 추가 촬영 여부
                        UserDefaults.standard.set(true, forKey: UserDefaultKey.isAppendingShoot)
                        coordinator.push(.camera(state: .appendShoot(guide: guide)))
                    },
                    onDragStateChanged: { isDragging in
                        viewModel.setDraggingState(isDragging)
                    }
                )
            }
        }
        .background(
            SnappieColor.darkHeavy
                .ignoresSafeArea()
        )
        .onAppear {
            Task {
                if let clip = newClip {
                    // 새 클립이 있는 경우: temp 초기화 후 클립 추가
                    await viewModel.initializeTempProject(loadAfter: false)
                    viewModel.addClipToTemp(clip: clip)
                    newClip = nil
                } else {
                    // 일반적인 경우: temp 초기화와 동시에 로드
                    await viewModel.initializeTempProject(loadAfter: true)
                }
            }
        }
        
        // 뒤로가기 확인 다이얼로그
        .confirmationDialog(
            "편집한 내용을 저장할까요?",
            isPresented: $showExitConfirmation,
            titleVisibility: .visible
        ) {
            Button("저장하기") {
                Task {
                    let success = await viewModel.commitChanges()
                    if success {
                        UserDefaults.standard.set(nil, forKey: UserDefaultKey.currentProjectID)
                        coordinator.popToScreen(.projectList)
                    }
                }
            }
            Button("저장하지 않고 나가기") {
                Task {
                    let success = await viewModel.discardChanges()
                    if success {
                        UserDefaults.standard.set(nil, forKey: UserDefaultKey.currentProjectID)
                        coordinator.popToScreen(.projectList)
                    }
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("저장하지 않으면 방금 편집한 내용이 사라져요.")
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
        
        // 모든 클립 삭제 시, 프로젝트 삭제 알림
        .alert(
            .emptyProjectDelete,
            isPresented: $viewModel.showEmptyProjectAlert,
            confirmAction: {
                Task {
                    let success = await viewModel.deleteEmptyProject()
                    if success {
                        coordinator.popToScreen(.projectList)
                    }
                }
            }
        )
    }
}
