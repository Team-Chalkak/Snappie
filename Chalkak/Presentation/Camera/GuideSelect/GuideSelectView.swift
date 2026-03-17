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

    @State private var viewModel: GuideSelectViewModel
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

        _viewModel = State(wrappedValue: GuideSelectViewModel(clipURL: clip.videoURL))
    }

    var body: some View {
        ZStack {
            SnappieColor.darkHeavy
                .ignoresSafeArea()

            VStack(alignment: .center, spacing: 16) {
                SnappieNavigationBar(
                    navigationTitle: Text("가이드 선택"),
                    leftButtonType: .backward {
                        coordinator.popLast()
                    },
                    rightButtonType: .oneButton(
                        .init(label: "완료") {
                            guard let previous = coordinator.previousPath else {
                                return
                            }

                            // 트리밍 시간을 원본시간으로 변환
                            let originalTimestamp = clip.startPoint + viewModel.startPoint

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
                    displayTime: viewModel.startPoint,
                    context: VideoContext(
                        previewImage: viewModel.previewImage,
                        player: viewModel.player,
                        isPlayerReady: viewModel.isPlayerReady,
                        isRebuildingPlayer: viewModel.isRebuildingPlayer,
                        isPlaying: viewModel.isPlaying,
                        currentTrimmedDuration: 0,
                        onTogglePlayback: { viewModel.togglePlayback() }
                    )
                )

                // 클립 시간 표시
                VStack(alignment: .center, spacing: 8) {
                    Divider()
                        .foregroundStyle(Color.deepGreen50.opacity(0.1))

                    ZStack(alignment: .center) {
                        Text("00:00")
                            .font(SnappieFont.style(.roundCaption1))
                            .foregroundStyle(SnappieColor.primaryHeavy)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 24)


                        Text((clip.endPoint - clip.startPoint).formattedTime)
                            .font(SnappieFont.style(.roundCaption1))
                            .foregroundStyle(SnappieColor.primaryHeavy)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 24)
                    }
                    // 하단 썸네일 부분
                    GuideFrameSelectorView(
                        state: FrameSelectorState(
                            thumbnails: viewModel.thumbnails,
                            duration: viewModel.duration,
                            startPoint: viewModel.startPoint,
                            thumbnailUnitWidth: { viewModel.thumbnailUnitWidth(for: $0) },
                            startX: { viewModel.startX(thumbnailLineWidth: $0, handleWidth: $1) }
                        ),
                        actions: FrameSelectorActions(
                            pause: { viewModel.player.pause() },
                            setNotPlaying: { viewModel.isPlaying = false },
                            updateStart: { viewModel.updateStart($0) },
                            seek: { viewModel.seek(to: $0) }
                        ),
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
            await viewModel.trimmedClip(
                trimStart: clip.startPoint,
                trimEnd: clip.endPoint
            )
            // 저장된 가이드 타임스탬프가 있으면 초기 프레임 위치로 반영
            if case .followUpShoot(let guide) = shootState {
                if let selectedTimestamp = guide.selectedTimestamp {
                    let clamped = max(0, min(selectedTimestamp - clip.startPoint, viewModel.duration))
                    viewModel.updateStart(clamped)
                    viewModel.seek(to: clamped)
                }
            } else if case .appendShoot(let guide) = shootState {
                if let selectedTimestamp = guide.selectedTimestamp {
                    let clamped = max(0, min(selectedTimestamp - clip.startPoint, viewModel.duration))
                    viewModel.updateStart(clamped)
                    viewModel.seek(to: clamped)
                }
            }
        }
    }
}
