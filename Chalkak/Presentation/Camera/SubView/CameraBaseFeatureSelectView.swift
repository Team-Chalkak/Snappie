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
        CircleIconButton(
            iconName: "timer",
            action: {},
            isSelected: false
        )
        .frame(maxWidth: .infinity)

        CircleIconButton(iconName: viewModel.isTorch ? "bolt.fill" : "bolt.slash", action: viewModel.switchTorch, isSelected: viewModel.isTorch)
            .frame(maxWidth: .infinity)

        CircleIconButton(
            iconName: "grid",
            action: {},
            isSelected: false
        )
        .frame(maxWidth: .infinity)

        CircleIconButton(
            iconName: "ruler",
            action: {},
            isSelected: false
        )
        .frame(maxWidth: .infinity)
    }
}
