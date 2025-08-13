//
//  CameraState.swift
//  Chalkak
//
//  Created by 배현진 on 8/13/25.
//

import SwiftData

enum CameraState: Equatable {
    case firstShooting(projectID: String)
    case guideCamera(guideID: String, projectID: String?)
    case addClip(projectID: String)
}
