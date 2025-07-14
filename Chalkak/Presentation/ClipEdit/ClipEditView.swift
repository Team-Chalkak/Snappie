//
//  ClipEditView.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

import SwiftUI
import SwiftData
import AVKit

/// 클립 편집 뷰
struct ClipEditView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject var viewModel: ClipEditViewModel
    @State private var isDragging = false
    
    init() {
        _viewModel = StateObject(wrappedValue: ClipEditViewModel(context: nil))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(alignment: .center, spacing: 30, content: {
                    
                    Spacer().frame(height: 0)

                    Text("사용할 부분만 트리밍 해주세요")

                    videoPreview

                    TrimmingLineView(viewModel: viewModel, isDragging: $isDragging)
                    
                })
                .navigationTitle("영상 트리밍")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("뒤로") {
                            print("뒤로가기 버튼 눌림")
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("다음") {
                            viewModel.prepareOverlay()
                        }
                    }
                }
                .navigationDestination(isPresented: $viewModel.isOverlayReady) {
                    OverlayView(viewModel: viewModel)
                }
                .onAppear {
                    viewModel.updateContext(modelContext)
                }
                
                if viewModel.isLoading {
                    ProgressView("윤곽선 생성 중...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - 비디오 프리뷰
    private var videoPreview: some View {
        Group {
            if isDragging, let previewImage = viewModel.previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 296, height: 526)
            } else if let player = viewModel.player {
                VideoPlayer(player: player)
                    .frame(width: 296, height: 526)
            } else {
                Text("영상을 불러오는 중...")
            }
        }
    }
}

#Preview {
    ClipEditView()
}
