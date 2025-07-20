//
//  Path.swift
//  Chalkak
//
//  Created by 배현진 on 7/16/25.
//

import Foundation

enum Path: Hashable {
    case clipEdit(clipURL: URL, isFirstShoot: Bool, guide: Guide?)
    case overlay(clipID: String)
    case boundingBox(guide: Guide, isFirstShoot: Bool)
    case projectPreview(finalVideoURL: URL)
}
