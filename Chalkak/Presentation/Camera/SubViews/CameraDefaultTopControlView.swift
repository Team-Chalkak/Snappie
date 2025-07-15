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
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                CircleIconButton(iconName: viewModel.showingCameraControl ? "chevron.up" : "chevron.down", action: viewModel.switchCameraControls,
                                 iconSize: (28, 37),
                                 isSelected: viewModel.showingCameraControl)
                    .frame(maxWidth: .infinity)
                    .disabled(viewModel.isTimerRunning) // 타이머 중 비활성화
                ForEach(0 ..< 3) { _ in
                    Spacer()
                        .frame(maxWidth: .infinity)
                }
            }
            if viewModel.showingCameraControl && !viewModel.isTimerRunning {
                HStack(alignment: .center, spacing: 0) {
                    if viewModel.showingTimerControl {
                        TimerOptionSelectView(viewModel: viewModel)
                    } else {
                        CameraBaseFeatureSelectView(viewModel: viewModel)
                    }
                }
            }
        }
        .opacity(viewModel.isTimerRunning ? 0.5 : 1.0)
    }
}
