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
            CameraPreviewView(session: viewModel.session, showGrid: $viewModel.isGrid, tabToFocus: viewModel.focusAtPoint)

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
        .onReceive(viewModel.videoSavedPublisher) { url in
            self.clipUrl = url
            let cameraSetting = viewModel.saveCameraSettingToUserDefaults()
            
            coordinator.push(.clipEdit(
                clipURL: url,
                isFirstShoot: isFirstShoot,
                guide: guide,
                cameraSetting: cameraSetting)
            )
        }
    }
}
