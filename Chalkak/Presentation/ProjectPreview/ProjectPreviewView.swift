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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("내보내기") {
                    Task {
                        await viewModel.exportToPhotos()
                    }
                }
            }
        }
        .alert("영상 저장이 완료되었어요", isPresented: $viewModel.isExportFinished) { }
        .onDisappear {
            // 뷰 해제 및 앱 백그라운드 상황에서도 삭제 작업 보장
            let taskID = UIApplication.shared.beginBackgroundTask(withName: "cleanTempVideo")
            
            Task.detached {
                await viewModel.cleanupTemporaryVideoFile()
                UIApplication.shared.endBackgroundTask(taskID)
            }
        }
    }
}

#Preview {
    ProjectPreviewView(finalVideoURL: URL(fileURLWithPath: ""))
}
