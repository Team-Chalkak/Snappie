//
//  BoundingBoxView.swift
//  Chalkak
//
//  Created by 배현진 on 7/14/25.
//

import SwiftUI

struct BoundingBoxView: View {
    let guide: Guide?
    let isFirstShoot: Bool

    @StateObject private var viewModel = BoundingBoxViewModel()
    @StateObject private var cameraViewModel = CameraViewModel()

    var body: some View {
        ZStack {
            if isFirstShoot {
                CameraView(isFirstShoot: isFirstShoot, guide: nil, viewModel: cameraViewModel)
            } else {
                if viewModel.isAligned {
                    Color.blue
                        .ignoresSafeArea()
                        .transition(.opacity)
                }

                CameraView(isFirstShoot: isFirstShoot, guide: guide, viewModel: cameraViewModel)
                    .onAppear {
                        cameraViewModel.setBoundingBoxUpdateHandler { bboxes in
                            viewModel.liveBoundingBoxes = bboxes
                        }
                    }

                if let guide = guide, let outline = guide.outlineImage {
                    Image(uiImage: outline)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 296, height: 526)
                        .allowsHitTesting(false)
                } else {
                    Text("윤곽선 이미지 없음")
                        .foregroundColor(.gray)
                        .allowsHitTesting(false)
                }

                // TODO: - Height, Tilt 피드백 뷰 띄우기
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
