//
//  Path.swift
//  Chalkak
//
//  Created by 배현진 on 7/16/25.
//

import Foundation

enum Path: Hashable {
    case clipEdit(clipURL: URL, isFirstShoot: Bool, guide: Guide?, cameraSetting: CameraSetting)
    case overlay(clipID: String, isFrontCamera: Bool)
    case boundingBox(guide: Guide, isFirstShoot: Bool)
}
