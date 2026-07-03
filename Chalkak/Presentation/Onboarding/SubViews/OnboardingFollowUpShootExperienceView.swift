//
//  OnboardingFollowUpShootExperienceView.swift
//  Chalkak
//
//  Created by 배현진 on 6/28/26.
//

import SwiftUI

struct OnboardingFollowUpShootExperienceView: View {
    let guide: Guide
    let onFinished: () -> Void
    let onExit: () -> Void

    @State private var route: OnboardingExperienceRoute = .camera
    @State private var isGuidePromptPresented = true

    var body: some View {
        ZStack {
            content

            if isGuidePromptPresented {
                OnboardingGuideCameraPromptOverlay(
                    lines: [
                        "가이드에 맞춰",
                        "다른 장면을 찍어주세요"
                    ]
                ) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isGuidePromptPresented = false
                    }
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isGuidePromptPresented)
    }

    @ViewBuilder
    private var content: some View {
        switch route {
        case .camera:
            GuideCameraView(
                guide: guide,
                shootState: .followUpShoot(guide: guide),
                onboardingVideoSaved: { url, setting, manager, tiltList in
                    route = .clipEdit(url, setting, manager, tiltList)
                },
                onboardingExit: {
                    onExit()
                }
            )

        case let .clipEdit(url, setting, manager, tiltList):
            ClipEditView(
                clipURL: url,
                shootState: .followUpShoot(guide: guide),
                cameraSetting: setting,
                cameraManager: manager,
                timeStampedTiltList: tiltList,
                onboardingFinishShoot: {
                    onFinished()
                },
                onboardingBack: {
                    route = .camera
                    isGuidePromptPresented = false
                }
            )

        default:
            EmptyView()
        }
    }
}
