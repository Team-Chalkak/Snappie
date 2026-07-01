//
//  OnboardingFirstShootExperienceView.swift
//  Chalkak
//
//  Created by 배현진 on 6/28/26.
//

import SwiftUI

struct OnboardingFirstShootExperienceView: View {
    let onFinished: (Guide) -> Void
    let onExit: () -> Void
    
    @State private var route: OnboardingExperienceRoute = .camera

    var body: some View {
        switch route {
        case .camera:
            FirstShootCameraView(
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
                shootState: .firstShoot,
                cameraSetting: setting,
                cameraManager: manager,
                timeStampedTiltList: tiltList,
                onboardingCompletion: { clip, setting, manager in
                    route = .guideSelect(clip, setting, manager)
                },
                onboardingBack: {
                    route = .camera
                }
            )

        case let .guideSelect(clip, setting, manager):
            GuideSelectView(
                clip: clip,
                shootState: .firstShoot,
                cameraSetting: setting,
                cameraManager: manager,
                onboardingCompletion: { selectedTimestamp in
                    route = .overlay(clip, setting, manager, selectedTimestamp)
                },
                onboardingBack: {
                    route = .clipEdit(clip.videoURL, setting, manager, clip.tiltList)
                }
            )

        case let .overlay(clip, setting, manager, selectedTimestamp):
            OverlayView(
                clip: clip,
                cameraSetting: setting,
                cameraManager: manager,
                selectedTimestamp: selectedTimestamp,
                onboardingCompletion: { guide in
                    onFinished(guide)
                }
            )
        }
    }
}
