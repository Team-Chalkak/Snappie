//
//  CameraRecordView.swift
//  Chalkak
//
//  Created by 정종문 on 7/14/25.
//

import SwiftUI

struct CameraRecordView: View {
    @ObservedObject var viewModel: CameraViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: 54, height: 54)
            
            Spacer()
            
            Button(action: {
                if viewModel.isRecording || viewModel.isTimerRunning {
                    viewModel.stopVideoRecording()
                } else {
                    viewModel.startVideoRecording()
                }
            }) {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 3)
                        .frame(width: 74, height: 74)
                        .foregroundColor(.white)
                    
                    if viewModel.isTimerRunning {
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    } else if !viewModel.isRecording {
                        Circle()
                            .fill(.white)
                            .frame(width: 62, height: 62)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.red)
                            .frame(width: 26, height: 26)
                    }
                }
            }
            
            Spacer()
            
            CircleIconButton(iconName: "arrow.trianglehead.2.clockwise.rotate.90", action: viewModel.changeCamera)
        }
        .padding(.bottom, 20)
        .padding(.horizontal, 15)
    }
}
