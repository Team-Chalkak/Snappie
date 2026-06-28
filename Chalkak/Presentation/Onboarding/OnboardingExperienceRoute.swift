//
//  OnboardingExperienceRoute.swift
//  Chalkak
//
//  Created by 배현진 on 6/28/26.
//

import Foundation

enum OnboardingExperienceRoute {
    case camera
    case clipEdit(URL, CameraSetting, CameraManager, [TimeStampedTilt])
    case guideSelect(Clip, CameraSetting, CameraManager)
    case overlay(Clip, CameraSetting, CameraManager, Double)
}
