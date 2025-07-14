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
            VStack(alignment: .center, spacing: 30, content: {
                
                Spacer().frame(height: 0)

                Text("사용할 부분만 트리밍 해주세요")
                
                videoPreview
                
                TrimmingLineView(viewModel: viewModel)
                
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
