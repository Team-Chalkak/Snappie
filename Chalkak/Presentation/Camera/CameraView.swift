//
//  CameraView.swift
//  Chalkak
//
//  Created by 정종문 on 7/12/25.
//

import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel: CameraViewModel = .init()

    @State private var clipUrl: URL?
    @State private var navigateToEdit = false

    var body: some View {
        NavigationStack {
            ZStack {
                CameraPreviewView(session: viewModel.session, showGrid: $viewModel.isGrid)

                VStack {
                    CameraTopControlView(viewModel: viewModel)

                    Spacer()

                    CameraBottomControlView(viewModel: viewModel)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .init("VideoSaved"))) { output in
                /// 촬영 완료 후 저장된 파일 URL을 NotificationCenter에서 받고 navigateToEdit 트리거
                if let userInfo = output.userInfo, let url = userInfo["url"] as? URL {
                    self.clipUrl = url
                    self.navigateToEdit = true
                }
            }

            .navigationDestination(isPresented: $navigateToEdit) {
                if let url = clipUrl {
                    ClipEditView(clipURL: url, isFirstShoot: true)
                }
            }
        }
    }
}
