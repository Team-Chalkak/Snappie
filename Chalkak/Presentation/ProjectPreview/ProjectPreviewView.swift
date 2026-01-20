//
//  ProjectPreviewView.swift
//  Chalkak
//
//  Created by 석민솔 on 7/17/25.
//

import AVKit
import FirebaseAnalytics
import SwiftUI

/// 합본 영상을 갤러리로 내보내고 확인할 수 있는 뷰
struct ProjectPreviewView: View {
    // MARK: Property Wrappers

    @StateObject private var viewModel: ProjectPreviewViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showExportSuccessAlert = false
    @State private var showPhotoPermissionDeniedAlert = false
    @State private var isExporting = false

    // MARK: Init

    init(editableClips: [EditableClip]) {
        self._viewModel = StateObject(wrappedValue: ProjectPreviewViewModel(editableClips: editableClips))
    }
   
    // MARK: body

    var body: some View {
        ZStack {
            SnappieColor.darkHeavy.ignoresSafeArea()

            VStack(alignment: .center, spacing: 8) {
                SnappieButton(.iconNormal(icon: .dismiss, size: .large)) {
                    dismiss()
                }
                .padding([.leading, .top])
                .frame(maxWidth: .infinity, alignment: .leading)

                if let player = viewModel.player {
                    VideoPlayer(player: player)
                        .frame(maxWidth: .infinity)
                } else {
                    Spacer()
                }
            }
        }
        .navigationBarBackButtonHidden()
        .snappieProgressAlert(
            isPresented: $viewModel.isExporting,
            isLoading: $viewModel.isExporting,
            loadingMessage: "내보내는 중...",
            completionMessage: "내보내기 완료"
        )
        .snappieAlert(
            isPresented: $showExportSuccessAlert,
            message: "내보내기 완료"
        )
        .alert(
            .photoPermissionDenied,
            isPresented: $showPhotoPermissionDeniedAlert,
            confirmAction: {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
        )
        .onAppear {
            Task {
                let success = await viewModel.exportAndSetPlayer()
                if success {
                    showExportSuccessAlert = true
                } else {
                    showPhotoPermissionDeniedAlert = true
                }
            }
        }
        .onDisappear {
            let taskID = UIApplication.shared.beginBackgroundTask(withName: "cleanTempVideo")

            Task.detached {
                await viewModel.cleanupTemporaryVideoFile()
                UIApplication.shared.endBackgroundTask(taskID)
            }
        }
    }
}

#Preview {
    ProjectPreviewView(editableClips: [])
}
