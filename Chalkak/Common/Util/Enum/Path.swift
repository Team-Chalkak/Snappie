//
//  Path.swift
//  Chalkak
//
//  Created by 배현진 on 7/16/25.
//

import Foundation

enum Path: Hashable {
    case clipEdit(clipURL: URL, state: ShootState,  cameraSetting: CameraSetting, cameraManager: CameraManager, TimeStampedTiltList: [TimeStampedTilt])
    case overlay(clip: Clip, cameraSetting: CameraSetting, cameraManager: CameraManager)
    case camera(state: ShootState)

    case projectPreview
    case projectEdit(projectID: String, newClip: Clip? = nil)
    case projectList
}
