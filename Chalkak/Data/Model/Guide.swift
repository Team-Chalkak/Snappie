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
    
    /// 여러 명의 바운딩 박스 정보 (위치 + 크기)
    var boundingBoxes: [BoundingBoxInfo]
    
    /// 카메라 기울기.
    var cameraTilt: Tilt
    
    /// 가이드 생성 당시 프리뷰가 미러였는지
    let wasMirroredAtCapture: Bool
        
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
    ///   - isFrontPosition: 촬영 당시 카메라의 전면 모드 여부 (기본값 false).
    ///   - createdAt: 생성 시각 (기본값은 현재 시간).
    init(
        clipID: String,
        boundingBoxes: [BoundingBoxInfo],
        outlineImage: UIImage,
        cameraTilt: Tilt,
        wasMirroredAtCapture: Bool = false, // 마이그레이션을 위해 기본값 추가
        createdAt: Date = .now
    ) {
        self.clipID = clipID
        self.boundingBoxes = boundingBoxes
        self.cameraTilt = cameraTilt
        self.wasMirroredAtCapture = wasMirroredAtCapture
        self.createdAt = createdAt
        self.outlineImageData = outlineImage.pngData() ?? Data()
    }
}

extension Guide: Hashable {
    static func == (lhs: Guide, rhs: Guide) -> Bool {
        lhs.clipID == rhs.clipID
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(clipID)
    }
}
