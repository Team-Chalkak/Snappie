//
//  BoundingBoxView.swift
//  Chalkak
//
//  Created by 배현진 on 7/14/25.
//

import SwiftUI

struct BoundingBoxView: View {
    let guide: Guide?

    @StateObject private var viewModel = BoundingBoxViewModel()
    @EnvironmentObject private var coordinator: Coordinator

    var body: some View {
        Group {
            if let guide = guide {
                GuideCameraView(guide: guide)
            } else {
                FirstShootCameraView()
            }
        }
        .onAppear {
            if guide == nil {
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
                    coordinator.push(.boundingBox(guide: resumeProjectGuide))
                }
            }
        )
    }
}
