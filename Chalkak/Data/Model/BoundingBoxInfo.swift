//
//  BoundingBoxInfo.swift
//  Chalkak
//
//  Created by 배현진 on 7/21/25.
//

import Foundation

/// Vision으로 추출한 Bounding Box 정보를 나타내는 구조체입니다.
struct BoundingBoxInfo: Codable {
    /// Bounding Box 의 위치 값
    var origin: PointWrapper
    /// Bounding Box 의 너비 값
    var scale: CGFloat
    /// Bounding Box 의 높이 값. 기존 데이터는 scale을 높이 fallback으로 사용합니다.
    var height: CGFloat?

    var cgRect: CGRect {
        CGRect(
            x: origin.x,
            y: origin.y,
            width: scale,
            height: height ?? scale
        )
    }
}

/// CGPoint를 SwiftData에 저장할 수 없어 CGFloat 형태로 변환하는 Wrapper 구조체입니다.
struct PointWrapper: Codable {
    var x: CGFloat
    var y: CGFloat
    
    init(_ point: CGPoint) {
        self.x = point.x
        self.y = point.y
    }
    
    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}
