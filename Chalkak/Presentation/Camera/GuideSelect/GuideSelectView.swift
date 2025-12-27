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
    let cameraSetting: CameraSetting
    let cameraManager: CameraManager

    @StateObject private var editViewModel: ClipEditViewModel
    @EnvironmentObject private var coordinator: Coordinator
    @State private var isDragging = false

    init(clip: Clip, cameraSetting: CameraSetting, cameraManager: CameraManager) {
        self.clip = clip
        self.cameraSetting = cameraSetting
        self.cameraManager = cameraManager

        // ClipEditViewModel 재사용 (트리밍 기능은 사용하지 않음)
        _editViewModel = StateObject(wrappedValue: ClipEditViewModel(
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
                        .init(label: "다음") {
                            coordinator.push(
                                .overlay(
                                    clip: clip,
                                    cameraSetting: cameraSetting,
                                    cameraManager: cameraManager,
                                    selectedTimestamp: editViewModel.startPoint
                                )
                            )
                        }
                    )
                )

                VideoControlView(
                    isDragging: isDragging,
                    overlayImage: nil,
                    isGuideSelectMode: true,
                    editViewModel: editViewModel
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

                        Text(clip.originalDuration.formattedTime)
                            .font(SnappieFont.style(.roundCaption1))
                            .foregroundStyle(SnappieColor.primaryHeavy)
                    }
                    .padding(.horizontal, 24)
                    // 하단 썸네일 부분
                    GuideFrameSelectorView(editViewModel: editViewModel, isDragging: $isDragging)
                        .padding(.horizontal, 26)
                }
            }
            .padding(.bottom, 14)
        }
        .navigationBarBackButtonHidden(true)
    }
}
