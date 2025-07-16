//
//  BoundingBoxView.swift
//  Chalkak
//
//  Created by 배현진 on 7/14/25.
//

import SwiftUI

struct BoundingBoxView: View {
    let guide: Guide?
    
    @StateObject private var viewModel = BoundingBoxViewModel()
    @StateObject private var cameraViewModel = CameraViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isAligned {
                    Color.blue
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
                
                CameraView(viewModel: cameraViewModel)
                    .onAppear {
                        cameraViewModel.setBoundingBoxUpdateHandler { bboxes in
                            viewModel.liveBoundingBoxes = bboxes
                        }
                    }
            }
            .onAppear() {
                if let guide = guide {
                    viewModel.setReference(from: guide)
                }
            }
            .onChange(of: viewModel.liveBoundingBoxes) {
                viewModel.compare()
            }
        }
    }
}
