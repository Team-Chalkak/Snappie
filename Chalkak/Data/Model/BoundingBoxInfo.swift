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
    /// Bounding Box 의 크기 값
    var scale: CGFloat
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
