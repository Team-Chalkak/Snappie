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
        CircleIconButton(iconName: "timer", action: viewModel.toggleTimerOption, isSelected: viewModel.selectedTimerDuration != .off)
            .frame(maxWidth: .infinity)

        CircleIconButton(iconName: viewModel.torchMode.iconName, action: viewModel.switchTorch, isSelected: viewModel.torchMode != .off)
            .frame(maxWidth: .infinity)

        CircleIconButton(iconName: "grid", action: viewModel.switchGrid, isSelected: viewModel.isGrid)
            .frame(maxWidth: .infinity)

        CircleIconButton(
            iconName: "ruler",
            action: viewModel.switchHorizontalLevel, isSelected: viewModel.isHorizontalLevelActive
        )
        .frame(maxWidth: .infinity)
    }
}
