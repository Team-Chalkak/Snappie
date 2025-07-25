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
 
 ## 서브뷰
 - VideoPreviewView: 영상의 현재 구간을 보여주는 프리뷰 뷰
 - TrimmingControlView: 영상 재생 버튼과 트리밍 타임라인 UI를 포함한 조작 패널
 
 ## 호출 위치
 - CameraView → ClipEditView로 이동
 - 호출 예시:
 */
struct ClipEditView: View {
    // 1. Input properties
    let guide: Guide?
    let cameraSetting: CameraSetting

    // 2. State & ObservedObject
    @StateObject private var editViewModel: ClipEditViewModel
    @EnvironmentObject private var coordinator: Coordinator
    @StateObject private var videoManager = VideoManager()
    @State private var isDragging = false
    @State private var autoPlayEnabled = true
    @State private var showActionSheet = false
    
    // 3. init
    init(
        clipURL: URL,
        guide: Guide?,
        cameraSetting: CameraSetting,
        timeStampedTiltList: [TimeStampedTilt]
    ) {
        _editViewModel = StateObject(wrappedValue: ClipEditViewModel(
            clipURL: clipURL,
            cameraSetting: cameraSetting,
            timeStampedTiltList: timeStampedTiltList
            )
        )
        self.guide = guide
        self.cameraSetting = cameraSetting
    }
    
    // 4. body
    var body: some View {
        ZStack {
            SnappieColor.darkHeavy
                .ignoresSafeArea()
            
            VStack(alignment: .center, spacing: 16, content: {
                SnappieNavigationBar(
                    navigationTitle: "클립 편집",
                    leftButtonType: .backward {
                        coordinator.popLast()
                    },
                    rightButtonType: guide != nil ?
                        .oneButton(
                            // 두번째 촬영 이후
                            .init(label: "완료") {
                                showActionSheet = true
                            }
                        ) :
                        .oneButton(
                            // 첫번째 촬영
                            .init(label: "다음") {
                                editViewModel.saveProjectData()
                                coordinator.push(
                                    .overlay(clip: editViewModel.createClipData())
                                )
                            }
                        )
                )

                VideoControlView(
                    isDragging: isDragging,
                    overlayImage: guide?.outlineImage,
                    editViewModel: editViewModel
                )

                TrimmingControlView(editViewModel: editViewModel, isDragging: $isDragging)
            })
            .padding(.bottom, 14)
        }
        .navigationBarBackButtonHidden(true)
        .confirmationDialog(
            "A Short Title is Best",
            isPresented: $showActionSheet,
            titleVisibility: .visible
        ) {
            Button("촬영 이어가기") {
                // 트리밍한 클립 프로젝트에 추가
                editViewModel.appendClipToCurrentProject()
                
                // 가이드 카메라로 이동
                if let guide = guide {
                    coordinator.push(.boundingBox(guide: guide))
                }
            }

            Button("촬영 프로세스 마치기") {
                // 트리밍한 클립 프로젝트에 추가
                editViewModel.appendClipToCurrentProject()
                
                coordinator.push(.boundingBox(guide: nil))
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("이어서 찍거나 전체 영상 편집으로 이동할 수 있습니다.")
        }
        .task {
            if guide != nil {
                editViewModel.applyReferenceDuration()
            }
        }
    }
}
