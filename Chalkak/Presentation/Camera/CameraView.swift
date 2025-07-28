//
//  CameraView.swift
//  Chalkak
//
//  Created by 정종문 on 7/12/25.
//

import SwiftUI

struct CameraView: View {
    let guide: Guide?
    let isAligned: Bool

    @ObservedObject var viewModel: CameraViewModel
    @EnvironmentObject private var coordinator: Coordinator

    @State private var clipUrl: URL?
    @State private var navigateToEdit = false

    var body: some View {
        ZStack {
            if isAligned {
                SnappieColor.primaryStrong.edgesIgnoringSafeArea(.all)
            } else {
                SnappieColor.darkHeavy.edgesIgnoringSafeArea(.all)
            }

            CameraPreviewView(
                session: viewModel.session,
                tabToFocus: viewModel.focusAtPoint,
                onPinchZoom: viewModel.selectZoomScale,
                currentZoomScale: viewModel.zoomScale,
                isUsingFrontCamera: viewModel.isUsingFrontCamera,
                showGrid: $viewModel.isGrid,
                isTimerRunning: viewModel.isTimerRunning,
                timerCountdown: viewModel.timerCountdown
            )
            .aspectRatio(9 / 16, contentMode: .fit)
            .clipped()
            .padding(.top, Layout.preViewTopPadding)
            .padding(.horizontal, Layout.preViewHorizontalPadding)
            .frame(maxHeight: .infinity, alignment: .top)

            // 수평 레벨 표시
            if viewModel.isHorizontalLevelActive {
                HorizontalLevelIndicatorView(gravityX: viewModel.tiltCollector.gravityX)
            }

            VStack {
                CameraTopControlView(viewModel: viewModel)

                Spacer()

                CameraBottomControlView(viewModel: viewModel)
            }.padding(.horizontal, Layout.cameraControlHorizontalPadding)
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
        .onAppear {
            viewModel.startCamera()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
    }
}

private extension CameraView {
    enum Layout {
        static let preViewTopPadding: CGFloat = 12
        static let preViewHorizontalPadding: CGFloat = 16
        static let cameraControlHorizontalPadding: CGFloat = 8
    }
}
