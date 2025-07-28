//
//  Path.swift
//  Chalkak
//
//  Created by 배현진 on 7/16/25.
//

import Foundation

enum Path: Hashable {
    case clipEdit(clipURL: URL, guide: Guide?, cameraSetting: CameraSetting, TimeStampedTiltList: [TimeStampedTilt])
    case overlay(clip: Clip)
    case boundingBox(guide: Guide?)
    case projectPreview(finalVideoURL: URL)
}
