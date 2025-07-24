//
//  CameraView.swift
//  Chalkak
//
//  Created by 정종문 on 7/12/25.
//

import SwiftUI

struct CameraView: View {
    let guide: Guide?

    @ObservedObject var viewModel: CameraViewModel
    @EnvironmentObject private var coordinator: Coordinator

    @State private var clipUrl: URL?
    @State private var navigateToEdit = false

    var body: some View {
        ZStack {
            SnappieColor.darkHeavy.edgesIgnoringSafeArea(.all)

            CameraPreviewView(
                session: viewModel.session,
                tabToFocus: viewModel.focusAtPoint,
                onPinchZoom: viewModel.selectZoomScale,
                currentZoomScale: viewModel.zoomScale,
                isUsingFrontCamera: viewModel.isUsingFrontCamera,
                showGrid: $viewModel.isGrid
            )
            .aspectRatio(9 / 16, contentMode: .fit)
            .clipped()
            .padding(.top, 12)
            .padding(.horizontal, 16)
            .frame(maxHeight: .infinity, alignment: .top)

            // 수평 레벨 표시
            if viewModel.isHorizontalLevelActive {
                HorizontalLevelIndicatorView(gravityX: viewModel.tiltCollector.gravityX)
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
                guide: guide,
                cameraSetting: cameraSetting,
                TimeStampedTiltList: viewModel.timeStampedTiltList
            )
            )
        }
    }
}

