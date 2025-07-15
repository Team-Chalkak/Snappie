//
//  CameraView.swift
//  Chalkak
//
//  Created by 정종문 on 7/12/25.
//

import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel: CameraViewModel = .init()

    var body: some View {
        ZStack {
            CameraPreviewView(session: viewModel.session, showGrid: $viewModel.isGrid)

            VStack {
                CameraTopControlView(viewModel: viewModel)

                Spacer()

                CameraBottomControlView(viewModel: viewModel)
            }
        }
    }
}
