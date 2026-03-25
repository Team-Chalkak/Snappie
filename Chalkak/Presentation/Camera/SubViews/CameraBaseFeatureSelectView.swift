//
//  CameraBaseFeatureSelectView.swift
//  Chalkak
//
//  Created by 정종문 on 7/14/25.
//

import FirebaseAnalytics
import SwiftUI

struct CameraBaseFeatureSelectView: View {
    var viewModel: CameraViewModel

    var body: some View {
        ButtonIconWithText(title: "Timer", icon: viewModel.currentTimerIcon, isActive: viewModel.selectedTimerDuration != .off) {
            viewModel.toggleTimerOption()
            Analytics.logEvent("toggleTimerButtonTapped", parameters: ["timerDuration" : viewModel.selectedTimerDuration.rawValue])
        }
        .frame(maxWidth: .infinity)

        SnappieButton(.iconWithText(title: "Flash", icon: viewModel.currentFlashIcon, isActive: viewModel.torchMode != .off)) {
            viewModel.switchTorch()
            Analytics.logEvent("toggleFlashButtonTapped", parameters: ["torchMode" : viewModel.torchMode])
        }.frame(maxWidth: .infinity)

        SnappieButton(.iconWithText(title: "Grid", icon: .grid, isActive: viewModel.isGrid)) {
            viewModel.switchGrid()
            Analytics.logEvent("toggleGridButtonTapped", parameters: ["gridMode" : viewModel.isGrid])
        }
        .frame(maxWidth: .infinity)

        SnappieButton(.iconWithText(title: "Level", icon: .level, isActive: viewModel.isHorizontalLevelActive)) {
            viewModel.switchHorizontalLevel()
            Analytics.logEvent("toggleLevelButtonTapped", parameters: ["horizontalLevelMode" : viewModel.isHorizontalLevelActive])
        }

        .frame(maxWidth: .infinity)
    }
}
