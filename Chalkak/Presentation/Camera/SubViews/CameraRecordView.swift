//
//  CameraRecordView.swift
//  Chalkak
//
//  Created by 정종문 on 7/14/25.
//

import SwiftData
import SwiftUI

struct CameraRecordView: View {
    @ObservedObject var viewModel: CameraViewModel
    @EnvironmentObject private var coordinator: Coordinator

    @Query(filter: #Predicate<Project> { project in
        project.isChecked == false
    }) private var uncheckedProjects: [Project]

    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                coordinator.push(.projectList)
            }) {
                Image(uncheckedProjects.isEmpty ? "projectList" : "projectListBadge")
                    .frame(width: 48, height: 48)
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
