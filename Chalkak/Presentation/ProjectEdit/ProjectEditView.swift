//
//  ProjectEditView.swift
//  Chalkak
//
//  Created by 배현진 on 7/24/25.
//

import AVKit
import FirebaseAnalytics
import SwiftUI

/// 프로젝트 편집 메인뷰
struct ProjectEditView: View {
    @State private var viewModel: ProjectEditViewModel
    @EnvironmentObject private var coordinator: Coordinator
    @State private var showExitConfirmation = false
    @State private var showPhotoPermissionDeniedAlert = false
    @State private var isOverlayVisible: Bool = true
    @State private var showExportView = false
    @State private var isSaving = false
    @State private var showSaveCompleteAlert: Bool = false

    // appendShoot에서 전달된 클립 데이터
    @State private var newClip: Clip? = nil

    init(projectID: String, newClip: Clip? = nil) {
        self._viewModel = State(wrappedValue: ProjectEditViewModel(projectID: projectID))
        self._newClip = State(initialValue: newClip)
    }

    var body: some View {
        VStack(spacing: 0) {
            SnappieNavigationBar(
                navigationTitle: viewModel.projectTitle,
                leftButtonType: .backward {
                    if viewModel.hasChanges && !isSaving {
                        showExitConfirmation = true
                    } else {
                        UserDefaults.standard.set(nil, forKey: UserDefaultKey.currentProjectID)
                        coordinator.popToScreen(.projectList)
                    }
                },
                rightButtonType: .twoButton(
                    primary: .init(label: "저장") {
                        Task {
                            isSaving = true
                            let success = await viewModel.commitChanges()
                            if success {
                                // 저장 후 새로운 temp 프로젝트 생성
                                await viewModel.initializeTempProject(loadAfter: true)
                                showSaveCompleteAlert = true
                            }
                            isSaving = false
                        }
                    },
                    secondary: .init(icon: .export) {
                        showExportView.toggle()
                    }
                )
            )
            .padding(.bottom, 16)
            
            VideoPreviewWithOverlay(
                previewImage: viewModel.previewImage,
                player: viewModel.player,
                isDragging: viewModel.isDragging,
                overlayImage: viewModel.guide?.outlineImage,
                isPlayerReady: viewModel.isPlayerReady,
                isRebuildingPlayer: viewModel.isRebuildingPlayer,
                isOverlayVisible: $isOverlayVisible
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .snappieProgress(isPresented: $viewModel.isLoading, message: "영상 불러오는 중")
            
            // 재생 일시정지 버튼 & 시간표시하는 서브뷰
            PlayInfoView(
                onPlayPauseTapped: viewModel.togglePlayback,
                currentTime: viewModel.playHead,
                totalDuration: viewModel.totalDuration,
                trimmingClip: nil,
                showOverlayToggle: viewModel.guide?.outlineImage != nil,
                isPlaying: $viewModel.isPlaying,
                isOverlayVisible: $isOverlayVisible
            )
            .padding(.top, 16)
            
            Rectangle()
                .fill(.deepGreen600)
                .frame(maxWidth: .infinity, maxHeight: 1.5)
                .padding(.vertical, 8)
            
            TrimminglineSliderView(
                clips: $viewModel.editableClips,
                playHeadPosition: $viewModel.playHead,
                isDragging: $viewModel.isDragging,
                selectedClipID: $viewModel.selectedClipID,
                isPlaying: viewModel.isPlaying,
                totalDuration: viewModel.totalDuration,
                guideClipID: viewModel.guide?.clipID,
                onSeek: viewModel.seekTo,
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
                },
                onClipTapped: { clipID in
                    viewModel.selectClip(id: clipID)
                },
                pixelOffsetForTime: { time in
                    viewModel.pixelOffset(for: time)
                },
                timeForPixelOffset: { offset in
                    viewModel.playTime(for: offset)
                }
            )

            // ClipToolbarView - 선택된 클립이 있을 때만 표시
            if let selectedClipID = viewModel.selectedClipID {
                ClipToolbarView(
                    hideToolbar: {
                        viewModel.selectedClipID = nil
                    },
                    onTapEditClip: {
                        guard let payload = viewModel.makeClipEditPayload(
                            selectedClipID: selectedClipID
                        ) else { return }

                        coordinator.push(.clipEdit(
                            clipURL: payload.clipURL,
                            state: payload.state,
                            cameraSetting: payload.cameraSetting,
                            cameraManager: CameraManager(),
                            TimeStampedTiltList: payload.tiltList,
                            clipID: payload.clip.id))
                    },
                    onTapEditGuide: {
                        viewModel.setCurrentProjectID()
                        guard let payload = viewModel.makeClipEditPayload(
                            selectedClipID: selectedClipID
                        ) else { return }
                        
                        coordinator.push(.guideSelect(
                            clip: payload.clip,
                            state: payload.state,
                            cameraSetting: payload.cameraSetting,
                            cameraManager: CameraManager())
                        )
                    },
                    onTapDeleteClip: {
                        viewModel.deleteClip(id: selectedClipID)
                    }
                )
                .padding(.top, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.selectedClipID != nil)
        .background(
            SnappieColor.darkHeavy
                .ignoresSafeArea()
        )
        .onAppear {
            Task {
                if !viewModel.isAlreadyInitialized {
                    // 임시 프로젝트 생성 및 초기 로드
                    await viewModel.initializeTempProject(loadAfter: true)
                    
                    if let clip = newClip {
                        viewModel.addClipToTemp(clip: clip)
                        newClip = nil
                    }
                    viewModel.isAlreadyInitialized = true
                } else {
                    // 데이터만 새로고침 (플레이어 재설정 등)
                    await viewModel.loadProject()
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
                Analytics.logEvent("saveEditProjectButtonTapped", parameters: nil)
            }
            Button("저장하지 않고 나가기") {
                Task {
                    let success = await viewModel.discardChanges()
                    if success {
                        UserDefaults.standard.set(nil, forKey: UserDefaultKey.currentProjectID)
                        coordinator.popToScreen(.projectList)
                    }
                }
                Analytics.logEvent("removeEditProjectButtonTapped", parameters: nil)
            }
            Button("취소", role: .cancel) {
                Analytics.logEvent("cancelButtonTapped", parameters: nil)
            }
        } message: {
            Text("저장하지 않으면 방금 편집한 내용이 사라져요.")
        }
        
        // 내보내기 시트
        .sheet(isPresented: $showExportView) {
            ProjectPreviewView(editableClips: viewModel.editableClips)
        }
        
        // 가이드 클립 삭제 시, 불가능 알림
        .alert(
            AlertType.cannotDeleteGuideClip.title,
            isPresented: $viewModel.showCannotDeletGuideClipAlert,
            actions: {
                Button("확인") {
                    print("삭제 못하고 확인버튼을 누르기")
                }
            },
            message: {
                Text(AlertType.cannotDeleteGuideClip.message)
            }
        )
        
        // 모든 클립 삭제 시, 프로젝트 삭제 알림
        .alert(
            AlertType.emptyProjectDelete.title,
            isPresented: $viewModel.showEmptyProjectAlert,
            actions: {
                Button(AlertType.emptyProjectDelete.confirmText, role: .destructive) {
                    Task {
                        let success = await viewModel.deleteEmptyProject()
                        if success {
                            coordinator.popToScreen(.projectList)
                        }
                    }
                }
                
                Button("취소", role: .cancel) {
                    print("삭제 취소")
                }
            },
            message: {
                Text(AlertType.emptyProjectDelete.message)
            }
        )

        // 사진 라이브러리 권한 허용이 되지 않았을 때 Alert
        .alert(
            .photoPermissionDenied,
            isPresented: $showPhotoPermissionDeniedAlert,
            confirmAction: {
                // 설정앱 이동
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
        )
        
        // 프로젝트 저장 커스텀 Alert
        .snappieProgressAlert(
            isPresented: $showSaveCompleteAlert,
            isLoading: $isSaving,
            loadingMessage: "저장 중...",
            completionMessage: "편집 내용 저장됨"
        )
    }
}

// MARK: - Subviews
/*
private extension ProjectEditView {
    @ViewBuilder
    var navigationBar: some View {
        ZStack {
            HStack {
                backButton
                Spacer()
                rightButtons
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var rightButtons: some View {
        HStack(spacing: 8) {
            exportButton
            saveButton
        }
    }

    private var backButton: some View {
        SnappieButton(
            .iconBackground(
                icon: .chevronBackward,
                size: .medium,
                isActive: true
            )
        ) {
            if viewModel.hasChanges {
                showExitConfirmation = true
            } else {
                UserDefaults.standard.set(nil, forKey: UserDefaultKey.currentProjectID)
                coordinator.popToScreen(.projectList)
            }
        }
    }

    private var exportButton: some View {
        Button {
            Task {
                let success = await viewModel.exportEditedVideoToPhotos()
                if success {
                    showExportSuccessAlert = true
                } else {
                    showPhotoPermissionDeniedAlert = true
                }
            }
        } label: {
            Image(systemName: "square.and.arrow.down")
                .frame(width: 20, height: 20)
                .foregroundStyle(SnappieColor.labelPrimaryNormal)
                .padding(6)
                .background(SnappieColor.containerFillNormal)
                .frame(width: 32, height: 32)
                .clipShape(.circle)
        }
    }

    private var saveButton: some View {
        Button {
            Task {
                let success = await viewModel.exportEditedVideoToPhotos()
                if success {
                    showExportSuccessAlert = true
                } else {
                    showPhotoPermissionDeniedAlert = true
                }
            }
        } label: {
            Text("저장")
                .font(SnappieFont.style(.proLabel2))
                .foregroundStyle(SnappieColor.labelPrimaryNormal)
                .padding(.horizontal, 20)
                .padding(.vertical, 9)
                .background(SnappieColor.containerFillNormal)
                .clipShape(.capsule)
        }
    }
}
*/
