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
        ButtonIconWithText(title: "Timer", icon: viewModel.currentTimerIcon, isActive: viewModel.selectedTimerDuration != .off) {
            viewModel.toggleTimerOption()
        }
        .frame(maxWidth: .infinity)

        SnappieButton(.iconWithText(title: "Flash", icon: viewModel.currentFlashIcon, isActive: viewModel.torchMode != .off)) {
            viewModel.switchTorch()
        }.frame(maxWidth: .infinity)

        SnappieButton(.iconWithText(title: "Grid", icon: .grid, isActive: viewModel.isGrid)) {
            viewModel.switchGrid()
        }
        .frame(maxWidth: .infinity)

        SnappieButton(.iconWithText(title: "Level", icon: .level, isActive: viewModel.isHorizontalLevelActive)) {
            viewModel.switchHorizontalLevel()
        }

        .frame(maxWidth: .infinity)
    }
}
