//
//  ClipEditView.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

import AVKit
import SwiftData
import SwiftUI

/// 클립 편집 뷰
struct ClipEditView: View {
    @StateObject private var editViewModel: ClipEditViewModel
    @StateObject private var overlayViewModel: OverlayViewModel
    @EnvironmentObject private var coordinator: Coordinator
    @StateObject private var videoManager = VideoManager()

    @State private var isDragging = false
    private var isFirstShoot: Bool = true
    let guide: Guide?
    
    @State private var navigateToCameraView = false
        
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

