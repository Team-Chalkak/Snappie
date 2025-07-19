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

 사용자가 영상에서 사용할 구간을 직접 선택(트리밍)할 수 있도록 도와주는 메인 View입니다.
 영상 재생, 썸네일 기반 트리밍, 클립 저장, 다음 단계(윤곽선 생성 또는 후속 클립 연결)로 이동하는 역할을 합니다.

 ## 데이터 흐름
 ⭐️ isFirstShoot 값에 따른 분기 처리
 ├─ true
 │    1) "내보내기" 버튼이 표시되지 않음
 │    2) "다음" 버튼 → Clip 및 Project 모델 생성 및 저장, UserDefaults에 Project ID 저장
 │    3) prepareOverlay() 호출하여 윤곽선 추출 준비
 ├─ false
      1) "내보내기" 버튼이 표시됨
      2) "다음" 버튼 → 기존 Project에 새로운 Clip 모델 추가
 
 ## 서브뷰
 - VideoPreviewView: 영상의 현재 구간을 보여주는 프리뷰 뷰
 - TrimmingControlView: 영상 재생 버튼과 트리밍 타임라인 UI를 포함한 조작 패널
 */
struct ClipEditView: View {
    // 1. Input properties
    let guide: Guide?
    private var isFirstShoot: Bool
    @State private var navigateToCameraView = false

    // 2. State & ObservedObject
    @StateObject private var editViewModel: ClipEditViewModel
    @StateObject private var overlayViewModel: OverlayViewModel
    @EnvironmentObject private var coordinator: Coordinator
    @StateObject private var videoManager = VideoManager()
    @State private var isDragging = false
        
    init(clipURL: URL, isFirstShoot: Bool, guide: Guide?) {
        _editViewModel = StateObject(wrappedValue: ClipEditViewModel(clipURL: clipURL))
        _overlayViewModel = StateObject(wrappedValue: OverlayViewModel())
        self.isFirstShoot = isFirstShoot
        self.guide = guide
    }
    
    
    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 20, content: {
                Spacer().frame(height: 20)

                Text("사용할 부분만 트리밍 해주세요")

                VideoPreviewView(
                    previewImage: editViewModel.previewImage,
                    player: editViewModel.player,
                    isDragging: isDragging
                )

                TrimmingControlView(editViewModel: editViewModel, isDragging: $isDragging)
            })

            //TODO: 추후 가이드 생성 화면 나오면 삭제
            if overlayViewModel.isLoading {
                ProgressView("윤곽선 생성 중...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .foregroundStyle(.white)
                    .tint(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
            }
        }
        .navigationTitle("영상 트리밍")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isFirstShoot {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // 현재까지 작업하던 영상 합쳐서 갤러리로 내보내기
                        Task {
                            editViewModel.appendClipToCurrentProject()
                            await videoManager.processAndSaveVideo()
                        }
                    } label: {
                        if videoManager.isProcessing {
                            ProgressView()
                        } else {
                            Text("내보내기")
                        }
                    }
                    .disabled(videoManager.isProcessing)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("다음") {
                    if isFirstShoot {
                        editViewModel.saveProjectData()
                        overlayViewModel.prepareOverlay(
                            from: editViewModel.clipURL,
                            at: editViewModel.startPoint
                        )
                    } else {
                        editViewModel.appendClipToCurrentProject()
                        if let guide = guide {
                            coordinator.push(.boundingBox(guide: guide, isFirstShoot: false))
                        }
                    }
                }
            }
        }
        .navigationDestination(isPresented: $overlayViewModel.isOverlayReady) {
            if let clipID = editViewModel.clipID {
                OverlayView(overlayViewModel: overlayViewModel, clipID: clipID)
            }
        }
    }
}

