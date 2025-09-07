//
//  CameraDefaultTopControlView.swift
//  Chalkak
//
//  Created by 정종문 on 7/14/25.
//

import SwiftUI

struct CameraDefaultTopControlView: View {
    @ObservedObject var viewModel: CameraViewModel

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                SnappieButton(.glassPill(
                    contentType: .icon(viewModel.showingCameraControl ? .chevronUp : .chevronDown),
                    isActive: viewModel.showingCameraControl
                )) {
                    viewModel.switchCameraControls()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .disabled(viewModel.isTimerRunning) // 타이머 중 비활성화
            }
            if viewModel.showingCameraControl && !viewModel.isTimerRunning {
                HStack {
                    CameraBaseFeatureSelectView(viewModel: viewModel)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(SnappieColor.gradientFillNormal)
                )
            }
        }
        .padding(.horizontal, 32)
        .opacity(viewModel.isTimerRunning ? 0.5 : 1.0)
    }
}
