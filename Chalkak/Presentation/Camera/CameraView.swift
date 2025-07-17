//
//  CameraView.swift
//  Chalkak
//
//  Created by 정종문 on 7/12/25.
//

import SwiftUI

struct CameraView: View {
    let isFirstShoot: Bool
    let guide: Guide?
    
    @ObservedObject var viewModel: CameraViewModel
    @EnvironmentObject private var coordinator: Coordinator

    @State private var clipUrl: URL?
    @State private var navigateToEdit = false

    var body: some View {
        ZStack {
            CameraPreviewView(session: viewModel.session, showGrid: $viewModel.isGrid)

            if viewModel.isHorizontalLevelActive {
                HStack {
                    Spacer()
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(viewModel.isHorizontal ? .green : .gray)
                    Spacer()
                }
                .padding(.horizontal, 100)
            }

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
                coordinator.push(.clipEdit(clipURL: url, isFirstShoot: isFirstShoot, guide: guide))
            }
        }
    }
}
