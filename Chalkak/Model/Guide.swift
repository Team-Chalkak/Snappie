//
//  Guide.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

import Foundation
import SwiftData
import UIKit

@Model
class Guide: Identifiable {
    @Attribute(.unique) var clipID: String
    var bBoxPosition: CGPoint
    var bBoxScale: CGFloat
    var cameraTilt: Tilt
    var cameraHeight: Float
    var createdAt: Date
    var outlineImageData: Data

    var outlineImage: UIImage? {
        UIImage(data: outlineImageData)
    }

    init(
        clipID: String,
        bBoxPosition: CGPoint,
        bBoxScale: CGFloat,
        outlineImage: UIImage,
        cameraTilt: Tilt,
        cameraHeight: Float,
        createdAt: Date = .now
    ) {
        self.clipID = clipID
        self.bBoxPosition = bBoxPosition
        self.bBoxScale = bBoxScale
        self.outlineImageData = outlineImage.pngData() ?? Data()
        self.cameraTilt = cameraTilt
        self.cameraHeight = cameraHeight
        self.createdAt = createdAt
    }
}
