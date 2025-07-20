//
//  CameraSetting.swift
//  Chalkak
//
//  Created by 배현진 on 7/19/25.
//

import Foundation
import SwiftData

/// 영상 데이터와 관련된 메타 정보를 저장하는 클립 모델입니다.
@Model
class CameraSetting {
    
    /// 프로젝트 카메라 설정의 고유 식별자.
    @Attribute(.unique) var id: String
    
    /// 카메라의 줌 정도
    var zoomScale: CGFloat
    
    /// 카메라의 그리드 기능 적용 여부
    var isGridEnabled: Bool
    
    /// 카메라의 전면 모드 여부
    var isFrontPosition: Bool
    
    /// 카메라의 타이머 적용 시간 (적용 안된 경우가 0초)
    var timerSecond: Int
    
    /// 새로운 Clip 인스턴스를 초기화합니다.
    /// - Parameters:
    ///   - id: 카메라 기본 설정의 고유 ID (기본값은 UUID).
    ///   - zoomScale: 카메라의 줌 정도.
    ///   - isGridEnabled: 카메라의 그리드 기능 적용 여부.
    ///   - isFrontPosition: 카메라의 전면 모드 여부.
    ///   - timerSecond: 카메라의 타이머 적용 시간.
    init(
        id: String = UUID().uuidString,
        zoomScale: CGFloat,
        isGridEnabled: Bool,
        isFrontPosition: Bool,
        timerSecond: Int = 0
    ) {
        self.id = id
        self.zoomScale = zoomScale
        self.isGridEnabled = isGridEnabled
        self.isFrontPosition = isFrontPosition
        self.timerSecond = timerSecond
    }
}
