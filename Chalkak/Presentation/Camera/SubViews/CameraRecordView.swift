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
                Image(systemName: "film.stack")
                    .font(.system(size: 32))
                    .foregroundStyle(SnappieColor.primaryLight)
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
            
            SnappieButton(.solidSecondary(contentType: .icon(.conversion), size: .medium, isOutlined: false)
            ) {
                viewModel.changeCamera()
            }
        }
        .padding(.bottom, 20)
        .padding(.horizontal, 20)
    }
}
