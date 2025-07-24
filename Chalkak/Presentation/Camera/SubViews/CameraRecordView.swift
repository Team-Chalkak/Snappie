//
//  CameraRecordView.swift
//  Chalkak
//
//  Created by 정종문 on 7/14/25.
//

import SwiftUI

struct CameraRecordView: View {
    @ObservedObject var viewModel: CameraViewModel
    @EnvironmentObject private var coordinator: Coordinator
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                coordinator.push(.projectEdit)
            }) {
                ZStack {
                    // TODO: - 이미지 표시 위한 분기 처리 필요
                    Color.gray
                        .frame(width: 70, height: 70)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            
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
            
            // 오른쪽 - 카메라 전환 버튼
            CircleIconButton(iconName: "arrow.trianglehead.2.clockwise.rotate.90", action: viewModel.changeCamera)
        }
        .padding(.bottom, 45)
        .padding(.horizontal, 15)
    }
}
