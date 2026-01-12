//
//  GuideSelectView.swift
//  Chalkak
//
//  Created by bishoe01 on 12/26/25.
//

import AVKit
import SwiftUI

/**
 GuideSelectView: 가이드 프레임 선택 화면

 ClipEditView와 거의 동일한 UI 구조를 가짐. 가이드 박스(흰색 박스)를 드래그하여 가이드 프레임을 선택
 */
struct GuideSelectView: View {
    let clip: Clip
    let shootState: ShootState
    let cameraSetting: CameraSetting
    let cameraManager: CameraManager

    @State private var editViewModel: ClipEditViewModel
    @EnvironmentObject private var coordinator: Coordinator
    @State private var isDragging = false

    private var overlayImage: UIImage? {
        switch shootState {
        case .firstShoot:
            return nil
        case .followUpShoot(let guide),
             .appendShoot(let guide):
            return guide.outlineImage
        }
    }

    init(
        clip: Clip,
        shootState: ShootState,
        cameraSetting: CameraSetting,
        cameraManager: CameraManager
    ) {
        self.clip = clip
        self.shootState = shootState
        self.cameraSetting = cameraSetting
        self.cameraManager = cameraManager

        // ClipEditViewModel 재사용 (트리밍 기능은 사용하지 않음)
        _editViewModel = State(wrappedValue: ClipEditViewModel(
            clipURL: clip.videoURL,
            cameraSetting: cameraSetting,
            timeStampedTiltList: []
        ))
    }

    var body: some View {
        ZStack {
            SnappieColor.darkHeavy
                .ignoresSafeArea()

            VStack(alignment: .center, spacing: 16) {
                SnappieNavigationBar(
                    navigationTitle: "가이드 선택",
                    leftButtonType: .backward {
                        coordinator.popLast()
                    },
                    rightButtonType: .oneButton(
                        .init(label: "완료") {
                            guard let previous = coordinator.previousPath else {
                                return
                            }

                            // 트리밍 시간을 원본시간으로 변환
                            let originalTimestamp = clip.startPoint + editViewModel.startPoint

                            coordinator.push(
                                .overlay(
                                    clip: clip,
                                    cameraSetting: cameraSetting,
                                    cameraManager: cameraManager,
                                    selectedTimestamp: originalTimestamp
                                )
                            )
                        }
                    )
                )

                VideoControlView(
                    isDragging: isDragging,
                    overlayImage: overlayImage,
                    previewImage: editViewModel.previewImage,
                    player: editViewModel.player,
                    isPlaying: editViewModel.isPlaying,
                    currentTrimmedDuration: editViewModel.currentTrimmedDuration,
                    togglePlayback: editViewModel.togglePlayback
                )

                // 클립 시간 표시
                VStack(alignment: .center, spacing: 8) {
                    Divider()
                        .foregroundStyle(Color.deepGreen50.opacity(0.1))

                    HStack {
                        Text("00:00")
                            .font(SnappieFont.style(.roundCaption1))
                            .foregroundStyle(SnappieColor.primaryHeavy)

                        Spacer()

                        Text((clip.endPoint - clip.startPoint).formattedTime)
                            .font(SnappieFont.style(.roundCaption1))
                            .foregroundStyle(SnappieColor.primaryHeavy)
                    }
                    .padding(.horizontal, 24)
                    // 하단 썸네일 부분
                    GuideFrameSelectorView(
                        state: editViewModel.makeTrimmingState(
                            thumbnailLineWidth: TimelineConstants.thumbnailLineWidth,
                            handleWidth: TimelineConstants.handleWidth
                        ),
                        actions: editViewModel.trimmingActions,
                        isDragging: $isDragging
                    )
                    .padding(.horizontal, 26)
                }
            }
            .padding(.bottom, 14)
        }
        .navigationBarBackButtonHidden(true)
        .task {
            // 트리밍된 구간만 보여주도록 설정
            await editViewModel.trimmedClip(
                trimStart: clip.startPoint,
                trimEnd: clip.endPoint
            )
            // 저장된 가이드 타임스탬프가 있으면 초기 프레임 위치로 반영
            if case .followUpShoot(let guide) = shootState {
                if let selectedTimestamp = guide.selectedTimestamp {
                    let clamped = max(0, min(selectedTimestamp - clip.startPoint, editViewModel.duration))
                    editViewModel.updateStart(clamped)
                    editViewModel.seek(to: clamped)
                }
            } else if case .appendShoot(let guide) = shootState {
                if let selectedTimestamp = guide.selectedTimestamp {
                    let clamped = max(0, min(selectedTimestamp - clip.startPoint, editViewModel.duration))
                    editViewModel.updateStart(clamped)
                    editViewModel.seek(to: clamped)
                }
            }
        }
    }
}
