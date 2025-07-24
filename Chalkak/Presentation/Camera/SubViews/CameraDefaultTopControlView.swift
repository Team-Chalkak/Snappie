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
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                Button(action: viewModel.switchCameraControls) {
                    Image(viewModel.showingCameraControl ? Icon.chevronUp.rawValue : Icon.chevronDown.rawValue)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(SnappieButtonStyle(
                    styler: GlassPillStyler(
                        contentType: .icon(viewModel.showingCameraControl ? .chevronUp : .chevronDown),
                        isActive: viewModel.showingCameraControl
                    )
                ))
                .frame(maxWidth: .infinity)
                .disabled(viewModel.isTimerRunning) // 타이머 중 비활성화
            }
            if viewModel.showingCameraControl && !viewModel.isTimerRunning {
                HStack(spacing: 32) {
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
