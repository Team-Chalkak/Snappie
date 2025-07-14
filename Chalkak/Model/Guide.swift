//
//  Guide.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

import Foundation
import SwiftData
import UIKit

/// Defines the bounding box and camera settings for aligning shots.
@Model
class Guide: Identifiable {
    /// ID of the related Clip.
    @Attribute(.unique) var clipID: String
    
    /// Bounding box position for alignment.
    var bBoxPosition: CGPoint
    
    /// Bounding box scale.
    var bBoxScale: CGFloat
    
    /// Camera tilt used when capturing the guide.
    var cameraTilt: Tilt
    
    /// Camera height used when capturing the guide.
    var cameraHeight: Float
    
    /// Timestamp when the guide was created.
    var createdAt: Date
    
    /// Image data showing the subject's outline.
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
        self.cameraTilt = cameraTilt
        self.cameraHeight = cameraHeight
        self.createdAt = createdAt
        self.outlineImageData = outlineImage.pngData() ?? Data()
    }
}
