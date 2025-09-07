//
//  CameraBottomControlView.swift
//  Chalkak
//
//  Created by 정종문 on 7/15/25.
//

import SwiftUI

struct CameraBottomControlView: View {
    @ObservedObject var viewModel: CameraViewModel

    var body: some View {
        VStack(spacing: 20) {
            if !viewModel.isUsingFrontCamera {
                CameraZoomControlView(viewModel: viewModel)
            }

            CameraRecordView(viewModel: viewModel)
        }
        .foregroundColor(.white)
    }
}
