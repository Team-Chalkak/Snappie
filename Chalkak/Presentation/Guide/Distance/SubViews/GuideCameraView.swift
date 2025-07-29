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

    init(guide: Guide?) {
        self.guide = guide

        let cameraVM = CameraViewModel()
        self._cameraViewModel = StateObject(wrappedValue: cameraVM)
        self._viewModel = StateObject(
            wrappedValue: BoundingBoxViewModel(
                properTilt: guide?.cameraTilt,
                tiltDataCollector: cameraVM.tiltCollector
            )
        )
    }

    var body: some View {
        ZStack {
            CameraView(guide: guide, isAligned: viewModel.isAligned, viewModel: cameraViewModel)
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
                    .padding(.top, 12)
                    .padding(.horizontal, 16)
                    .frame(maxHeight: .infinity, alignment: .top)
            } else {
                Text("가이드를 생성하지못했어요.\n인물이 나오는 장면을 촬영해주세요")
                    .foregroundColor(SnappieColor.labelPrimaryNormal)
                    .allowsHitTesting(false)
                    .multilineTextAlignment(.center)
            }

            // Tilt 피드백 뷰
            if let tiltManager = viewModel.tiltManager {
                TiltFeedbackView(offsetX: tiltManager.offsetX, offsetY: tiltManager.offsetZ)
            }
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
