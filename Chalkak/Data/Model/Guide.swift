//
//  Guide.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

import Foundation
import SwiftData
import UIKit

/// 클립 간의 구도 일치를 위한 가이드 정보를 담는 모델입니다.
@Model
class Guide: Identifiable {
    /// 가이드가 연결된 클립의 ID.
    @Attribute(.unique) var clipID: String
    
    /// 화면 내 바운딩 박스의 위치.
    var bBoxPosition: PointWrapper
    
    /// 카메라로부터의 거리 비교를 위한 바운딩 박스의 크기.
    var bBoxScale: CGFloat
    
    /// 카메라 기울기.
    var cameraTilt: Tilt
    
    /// 카메라 높이.
    var cameraHeight: Float
    
    /// 가이드가 생성된 시점.
    var createdAt: Date
    
    /// 윤곽선 이미지의 바이너리 데이터.
    var outlineImageData: Data

    /// 윤곽선 이미지 데이터에서 생성된 UIImage.
    var outlineImage: UIImage? {
        UIImage(data: outlineImageData)
    }

    /// 새로운 `Guide` 인스턴스를 초기화합니다.
    /// - Parameters:
    ///   - clipID: 연결된 클립의 ID.
    ///   - bBoxPosition: 바운딩 박스의 위치.
    ///   - bBoxScale: 바운딩 박스의 크기.
    ///   - outlineImage: 윤곽선 이미지.
    ///   - cameraTilt: 촬영 당시의 카메라 기울기.
    ///   - cameraHeight: 촬영 당시의 카메라 높이.
    ///   - createdAt: 생성 시각 (기본값은 현재 시간).
    init(
        clipID: String,
        bBoxPosition: PointWrapper,
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

struct PointWrapper: Codable {
    var x: CGFloat
    var y: CGFloat
    
    init(_ point: CGPoint) {
        self.x = point.x
        self.y = point.y
    }
    
    var cgPoint: CGPoint {
        CGPoint(x: x, y: y * 0.7)
    }
}
