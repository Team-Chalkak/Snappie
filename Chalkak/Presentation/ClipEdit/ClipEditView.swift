//
//  ClipEditView.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

import AVKit
import SwiftData
import SwiftUI

/**
 ClipEditView: 영상 클립을 트리밍하는 사용자 인터페이스

 사용자가 영상에서 사용할 구간을 직접 선택(트리밍)할 수 있도록 도와주는 메인 View
 영상 재생, 썸네일 기반 트리밍, 클립 저장, 다음 단계(윤곽선 생성 또는 후속 클립 연결)로 이동하는 역할

 ## 데이터 흐름
 ⭐️ guide 값(nil 여부)에 따른 분기 처리
 ├─ guide == nil
 │    1) "내보내기" 버튼이 표시되지 않음
 │    2) "다음" 버튼 → Clip 및 Project 모델 생성 및 저장, UserDefaults에 Project ID 저장
 │    3) prepareOverlay() 호출하여 윤곽선 추출 준비
 ├─ guide != nil
      1) "내보내기" 버튼이 표시됨
      2) "다음" 버튼 → 기존 Project에 새로운 Clip 모델 추가

 ## 구성 요소(서브뷰)
 - VideoPreviewView: 영상의 현재 구간을 보여주는 프리뷰 뷰
 - TrimmingControlView: 영상 재생 버튼과 트리밍 타임라인 UI를 포함한 조작 패널

 ## 호출 위치
 - CameraView → ClipEditView로 이동
 - 호출 예시:
    ClipEditView(
        clipURL: url,
        guide: guide,
        cameraSetting: cameraSetting,
        timeStampedTiltList: timeStampedTiltList
    )
 */
struct ClipEditView: View {
    // 1. Input properties
    let shootState: ShootState
    let cameraSetting: CameraSetting

    // 2. State & ObservedObject
    @StateObject private var editViewModel: ClipEditViewModel
    @EnvironmentObject private var coordinator: Coordinator
    @StateObject private var videoManager = VideoManager()
    @State private var isDragging = false
    @State private var autoPlayEnabled = true
    @State private var showActionSheet = false
    @State private var showRetakeAlert = false
    
    // 3. 계산 프로퍼티
    private var guide: Guide? {
        switch shootState {
        case .firstShoot:
            return nil
        case .followUpShoot(let guide), .appendShoot(let guide):
            return guide
        }
    }

    // 4. init
    init(
        clipURL: URL,
        shootState: ShootState,
        cameraSetting: CameraSetting,
        timeStampedTiltList: [TimeStampedTilt]
    ) {
        _editViewModel = StateObject(wrappedValue: ClipEditViewModel(
                clipURL: clipURL,
                cameraSetting: cameraSetting,
                timeStampedTiltList: timeStampedTiltList
            )
        )
        self.shootState = shootState
        self.cameraSetting = cameraSetting
    }

    // 5. body
    var body: some View {
        ZStack {
            SnappieColor.darkHeavy
                .ignoresSafeArea()

            VStack(alignment: .center, spacing: 16) {
                SnappieNavigationBar(
                    navigationTitle: "장면 다듬기",
                    leftButtonType: .backward {
                        showRetakeAlert = true
                    },
                    rightButtonType: .oneButton(
                        .init(label: shootState == .firstShoot ? "다음" : "완료") {
                            print("▶️ Right button tapped. shootState:", shootState)
                            switch shootState {
                            case .firstShoot:
                                coordinator.push(
                                    .overlay(
                                        clip: editViewModel.createClipData(),
                                        cameraSetting: editViewModel.cameraSetting
                                    )
                                )
                            case .followUpShoot:
                                showActionSheet = true
                            case .appendShoot:
                                let clipData = editViewModel.createTempClipData()
                                
                                if let projectID = editViewModel.fetchCurrentProjectID() {
                                    editViewModel.clearCurrentProjectID()
                                    coordinator.push(.projectEdit(projectID: projectID, tempClipData: clipData))
                                }
                            }
                        }
                    )
                )

                VideoControlView(
                    isDragging: isDragging,
                    overlayImage: guide?.outlineImage,
                    editViewModel: editViewModel
                )

                TrimmingControlView(editViewModel: editViewModel, isDragging: $isDragging)
            }
            .padding(.bottom, 14)
        }
        .onAppear {
            print("🔹 ClipEditView appeared. shootState:", shootState)
        }
        .navigationBarBackButtonHidden(true)
        .confirmationDialog(
            "다음 장면을 이어서 촬영할까요?",
            isPresented: $showActionSheet,
            titleVisibility: .visible
        ) {
            Button("이어서 촬영하기") {
                // 트리밍한 클립 프로젝트에 추가
                editViewModel.appendClipToCurrentProject()

                // 가이드 카메라로 이동
                if let guide = guide {
                    coordinator.push(.camera(state: .followUpShoot(guide: guide)))
                }
            }

            Button("촬영 마치기") {
                // 트리밍한 클립 프로젝트에 추가
                editViewModel.appendClipToCurrentProject()
                coordinator.push(.projectPreview)
            }

            Button("취소", role: .cancel) {}
        } message: {
            Text("지금 이어서 찍거나, 프로젝트를 마무리할 수 있어요.")
        }
        .alert(.retakeVideo, isPresented: $showRetakeAlert) {
            coordinator.popLast()
        }
        .task {
            if shootState != .firstShoot {
                editViewModel.applyReferenceDuration()
            }
        }
    }
}
