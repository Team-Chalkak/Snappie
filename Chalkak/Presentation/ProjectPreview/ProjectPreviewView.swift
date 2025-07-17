//
//  ProjectPreviewView.swift
//  Chalkak
//
//  Created by 석민솔 on 7/17/25.
//

import AVKit
import SwiftUI

/// 합본 영상을 확인하고 갤러리로 내보내기 할 수 있는 뷰
struct ProjectPreviewView: View {
    @StateObject var viewModel: ProjectPreviewViewModel
    
    init(finalVideoURL: URL) {
        _viewModel = StateObject(wrappedValue: ProjectPreviewViewModel(finalVideoURL: finalVideoURL))
    }
    
    var body: some View {
        VStack {
            VideoPlayer(player: viewModel.player)
        }
        .onDisappear {
            Task {
                await viewModel.cleanupTemporaryVideoFile()
            }
        }
    }
}

#Preview {
    ProjectPreviewView(finalVideoURL: URL(fileURLWithPath: ""))
}
