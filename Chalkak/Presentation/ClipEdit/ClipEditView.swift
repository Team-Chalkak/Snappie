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
    
    init() {
        _viewModel = StateObject(wrappedValue: ClipEditViewModel(context: nil))
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 15, content: {
                videoPreview
                
                Divider()

                trimmingSliders
                
                Spacer()
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
                        print("다음 버튼 눌림")
                    }
                }
            }
            .onAppear {
                viewModel.updateContext(modelContext)
            }
        }
    }
    
    // MARK: - 비디오 프리뷰
    private var videoPreview: some View {
        Group {
            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .scaledToFill()
                    .onAppear {
                        player.play()
                    }
            } else {
                Text("영상을 불러오는 중...")
            }
        }
    }

    // MARK: - 트리밍 슬라이더
    private var trimmingSliders: some View {
        TrimmingSliderView(viewModel: viewModel)
    }
}

#Preview {
    ClipEditView()
}
