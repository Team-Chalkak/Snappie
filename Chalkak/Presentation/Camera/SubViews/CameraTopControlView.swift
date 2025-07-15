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
                Text(viewModel.formattedTime)
                    .foregroundColor(.black)
                    .font(.system(size: 18, weight: .medium))
                    .padding(.all, 8)
                    .background(.white)
                    .cornerRadius(10)
            } else {
                CameraDefaultTopControlView(viewModel: viewModel)
            }
        }.padding(.top, 50)
    }
}
