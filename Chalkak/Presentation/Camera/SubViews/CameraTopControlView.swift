//
//  CameraTopControlView.swift
//  Chalkak
//
//  Created by 정종문 on 7/15/25.
//

import SwiftUI

struct CameraTopControlView: View {
    @ObservedObject var viewModel: CameraViewModel

    var body: some View {
        HStack {
            if viewModel.isTimerRunning {
                // 타이머 카운트다운 표시
                Text("\(viewModel.timerCountdown)")
                    .foregroundColor(.white)
                    .font(.system(size: 48, weight: .bold))
                    .frame(width: 80, height: 80)
                    .background(Color.black.opacity(0.7))
                    .clipShape(Circle())
                    .scaleEffect(viewModel.timerCountdown > 0 ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.5), value: viewModel.timerCountdown)
            } else if viewModel.isRecording {
                HStack(spacing: 3) {
                    Circle()
                        .fill(SnappieColor.redRecording)
                        .frame(width: 8, height: 8)
                    Text(viewModel.formattedTime)
                        .font(SnappieFont.style(.kronaLabel1))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(SnappieColor.gradientFillNormal)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                CameraDefaultTopControlView(viewModel: viewModel)
            }
        }.padding(.top, 50)
    }
}
