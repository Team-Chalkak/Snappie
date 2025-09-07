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
    // MARK: Property Wrappers

    @StateObject private var viewModel = ProjectPreviewViewModel()
    @EnvironmentObject private var coordinator: Coordinator
    @State private var showExportSuccessAlert = false
   
    // MARK: body

    var body: some View {
        ZStack {
            SnappieColor.darkHeavy.ignoresSafeArea()

            VStack(alignment: .center, spacing: 8, content: {
                SnappieNavigationBar(
                    leftButtonType: .dismiss {
                        viewModel.clearCurrentProjectID()

                        // 홈으로 이동 후 alert를 위한 userdefaults플래그 설정
                        UserDefaults.standard.set(true, forKey: "showProjectSavedAlert")

                        coordinator.removeAll()
                    },
                    rightButtonType: .oneButton(.init(
                        label: "내보내기",
                        action: {
                            Task {
                                await viewModel.exportToPhotos()
                                showExportSuccessAlert = true
                            }
                        }
                    ))
                )

                if let player = viewModel.player {
                    VideoPlayer(player: player)
                        .frame(maxWidth: .infinity)
                } else {
                    Spacer()
                }
            })
        }
        .navigationBarBackButtonHidden()
        .snappieAlert(isPresented: $showExportSuccessAlert, message: "내보내기 완료")
        .snappieProgressAlert(
            isPresented: $viewModel.isMerging,
            isLoading: $viewModel.isMerging,
            loadingMessage: "영상 생성 중...",
            completionMessage: ""
        )
        .onAppear {
            Task {
                await viewModel.startMerging()
            }
        }
        .onDisappear {
            // ✅ 원래 네가 작성한 클린업 로직 유지
            let taskID = UIApplication.shared.beginBackgroundTask(withName: "cleanTempVideo")

            Task.detached {
                await viewModel.cleanupTemporaryVideoFile()
                UIApplication.shared.endBackgroundTask(taskID)
            }
        }
    }
}

#Preview {
    ProjectPreviewView()
}
