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
        project.isChecked == false && project.guide != nil
    }) private var uncheckedProjects: [Project]

    // unchecked시 현재 촬영 중인 프로젝트를 제외
    private var uncheckedProjectsExcludingCurrent: [Project] {
        guard let currentProjectID = UserDefaults.standard.string(forKey: "currentProjectID") else {
            return uncheckedProjects
        }
        return uncheckedProjects.filter { $0.id != currentProjectID }
    }

    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                coordinator.push(.projectList)
            }) {
                Image(uncheckedProjectsExcludingCurrent.isEmpty ? "projectList" : "projectListBadge")
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
