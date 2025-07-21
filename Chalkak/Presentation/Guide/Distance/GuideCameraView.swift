//
//  GuideCameraView.swift
//  Chalkak
//
//  Created by 배현진 on 7/22/25.
//

import SwiftUI

struct GuideCameraView: View {
    let guide: Guide?

    @StateObject private var viewModel = BoundingBoxViewModel()
    @StateObject private var cameraViewModel = CameraViewModel()

    var body: some View {
        ZStack {
            if viewModel.isAligned {
                Color.blue
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            CameraView(isFirstShoot: false, guide: guide, viewModel: cameraViewModel)
                .onAppear {
                    cameraViewModel.setBoundingBoxUpdateHandler { bboxes in
                        viewModel.liveBoundingBoxes = bboxes
                    }
                }

            if let guide = guide, let outline = guide.outlineImage {
                Image(uiImage: outline)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .allowsHitTesting(false)
                    .scaleEffect(x: cameraViewModel.isUsingFrontCamera ? -1 : 1, y: 1)
            } else {
                Text("윤곽선 이미지 없음")
                    .foregroundColor(.gray)
                    .allowsHitTesting(false)
            }

            // TODO: - Height, Tilt 피드백 뷰 띄우기
        }
        .onAppear {
            if let guide = guide {
                viewModel.setReference(from: guide)
            }
        }
        .onChange(of: viewModel.liveBoundingBoxes) {
            viewModel.compare()
        }
    }
}
