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
    @State private var hasBadge = false

    // SwiftDataManager를 통한 뱃지 상태 확인
    private func updateBadgeState() {
        let uncheckedProjects = SwiftDataManager.shared.getUncheckedProjectsForBadge()
        hasBadge = !uncheckedProjects.isEmpty
    }

    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                coordinator.push(.projectList)
            }) {
                Image(hasBadge ? "projectListBadge" : "projectList")
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
        .onAppear {
            updateBadgeState()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            // SwiftData 변경사항이 있을 때 뱃지 상태 업데이트
            updateBadgeState()
        }
    }
}

private extension Layout {
    static let recordButtonSize = CGSize(width: 70, height: 70)
    static let recordButtonBottomPadding: CGFloat = 20
    static let recordButtonHorizontalPadding: CGFloat = 20
}
