//
//  BoundingBoxView.swift
//  Chalkak
//
//  Created by 배현진 on 7/14/25.
//

import SwiftUI

struct BoundingBoxView: View {
    let shootState: ShootState

    @StateObject private var viewModel = BoundingBoxViewModel()
    @EnvironmentObject private var coordinator: Coordinator

    var body: some View {
        Group {
            switch shootState {
            case .firstShoot:
                FirstShootCameraView()
            case .followUpShoot(let guide),
                 .appendShoot(let guide):
                GuideCameraView(guide: guide)
            }
        }
        .onAppear {
            if case .firstShoot = shootState {
                viewModel.checkResumeProject()
            }
        }
        .alert(
            .resumeProject,
            isPresented: $viewModel.showResumeAlert,
            cancelAction: {
                viewModel.cancelResume()
            },
            confirmAction: {
                if let resumeProjectGuide = viewModel.loadGuideForCurrentProject() {
                    coordinator.push(.camera(state: .followUpShoot(guide: resumeProjectGuide)))
                }
            }
        )
    }
}
