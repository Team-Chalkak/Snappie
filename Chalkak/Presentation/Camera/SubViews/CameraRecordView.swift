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
                coordinator.push(.projectList)
            }) {
                ZStack {
                    // TODO: - 이미지 표시 위한 분기 처리 필요
                    Color.gray
                        .frame(width: Layout.recordButtonSize.width, height: Layout.recordButtonSize.height)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
        .padding(.bottom, Layout.recordButtonBottomPadding)
        .padding(.horizontal, Layout.recordButtonHorizontalPadding)
    }
}

private extension Layout {
    static let recordButtonSize = CGSize(width: 70, height: 70)
    static let recordButtonBottomPadding: CGFloat = 20
    static let recordButtonHorizontalPadding: CGFloat = 20
}
