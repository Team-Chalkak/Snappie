//
//  CameraBaseFeatureSelectView.swift
//  Chalkak
//
//  Created by 정종문 on 7/14/25.
//

import SwiftUI

struct CameraBaseFeatureSelectView: View {
    @ObservedObject var viewModel: CameraViewModel

    var body: some View {
        ButtonIconWithText(title: "Timer", icon: .timer3sec, isActive: viewModel.selectedTimerDuration != .off) {
            viewModel.toggleTimerOption()
        }
        .frame(maxWidth: .infinity)

        ButtonIconWithText(title: "Flash", icon: .flashOff, isActive: viewModel.torchMode != .off) {
            viewModel.switchTorch()
        }
        .frame(maxWidth: .infinity)

        ButtonIconWithText(title: "Grid", icon: .grid, isActive: viewModel.isGrid) {
            viewModel.switchGrid()
        }
            .frame(maxWidth: .infinity)

        ButtonIconWithText(title: "Level", icon: .level, isActive: viewModel.isHorizontalLevelActive) {
            viewModel.switchHorizontalLevel()
        }
        .frame(maxWidth: .infinity)
    }
}
