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

    var body: some View {
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
                onboardingCompletion: nil,
                onboardingFinishShoot: {
                    onFinished()
                },
                onboardingBack: {
                    route = .camera
                }
            )

        default:
            EmptyView()
        }
    }
}
