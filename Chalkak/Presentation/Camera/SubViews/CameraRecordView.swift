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
            Button(action: {}) {
                Image(systemName: "square.stack")
                    .font(.system(size: 54))
            }
            Spacer()
            
            RecordButton(
                isRecording: viewModel.isRecording,
                isTimerRunning: viewModel.isTimerRunning
            ) {
                if viewModel.isRecording || viewModel.isTimerRunning {
                    viewModel.stopVideoRecording()
                } else {
                    viewModel.startVideoRecording()
                }
            }
            
            Spacer()
            
            Button(action: viewModel.changeCamera) {
                Image(Icon.conversion.rawValue)
                    .font(.system(size: 20))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 6)
            .frame(width: 56, height: 32)
            .background(
                Capsule()
                    .fill(SnappieColor.containerFillNormal)
            )
        }
        .padding(.bottom, 20)
        .padding(.horizontal, 20)
    }
}
