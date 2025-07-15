//
//  BoundingBoxView.swift
//  Chalkak
//
//  Created by 배현진 on 7/14/25.
//

import SwiftUI

struct BoundingBoxView: View {
    @StateObject private var viewModel = BoundingBoxViewModel()
    @StateObject private var cameraViewModel = CameraViewModel()

    var body: some View {
        ZStack {
            if viewModel.isAligned {
                Color.blue
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            CameraView()
                .onAppear {
                    cameraViewModel.setBoundingBoxUpdateHandler { bboxes in
                        viewModel.liveBoundingBoxes = bboxes
                    }
                }
        }
        .onAppear() {
            viewModel.setReference()
        }
        .onChange(of: viewModel.liveBoundingBoxes) {
            viewModel.compare()
        }
    }
}
