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
    @Environment(\.modelContext) private var modelContext
    @StateObject private var editViewModel: ClipEditViewModel
    @StateObject private var overlayViewModel: OverlayViewModel
    
    @State private var isDragging = false
    private var isFirstShoot: Bool = true
    
    @State private var navigateToCameraView = false
        
    init(clipURL: URL, isFirstShoot: Bool) {
        _editViewModel = StateObject(wrappedValue: ClipEditViewModel(context: nil, clipURL: clipURL))
        _overlayViewModel = StateObject(wrappedValue: OverlayViewModel())
        self.isFirstShoot = isFirstShoot
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
                        Button("내보내기") {
                            // TODO: 내보내기 기능 구현
                            print("내보내기 버튼 눌림")
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("다음") {
                        if isFirstShoot {
                            overlayViewModel.prepareOverlay(
                                from: editViewModel.clipURL,
                                at: editViewModel.startPoint
                            )
                        } else {
                            navigateToCameraView = true
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $overlayViewModel.isOverlayReady) {
                OverlayView(overlayViewModel: overlayViewModel)
            }
            .navigationDestination(isPresented: $navigateToCameraView) {
                //TODO: - 가이드 있는 카메라 뷰파인더로 연결(Berry)
            }
            .onAppear {
                editViewModel.updateContext(modelContext)
            }
    }
}

