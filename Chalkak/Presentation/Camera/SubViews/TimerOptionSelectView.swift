//
//  TimerOptionSelectView.swift
//  Chalkak
//
//  Created by 정종문 on 7/12/25.
//

import SwiftUI

struct TimerOptionSelectView: View {
    @ObservedObject var viewModel: CameraViewModel
    var body: some View {
        HStack(spacing: 0) {
            CircleIconButton(iconName: "timer", action: viewModel.toggleTimerOption, isSelected: viewModel.selectedTimerDuration != .off)
                .frame(maxWidth: .infinity)

            // 타이머 옵션
            ForEach(TimerOptions.allCases, id: \.self) { duration in
                Button(action: {
                    viewModel.selectTimer(duration)
                }) {
                    Text(duration.displayText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(viewModel.selectedTimerDuration == duration ? .blue : .white)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .background(
            Color.black.opacity(0.6)
                .cornerRadius(25)
        )
    }
}
