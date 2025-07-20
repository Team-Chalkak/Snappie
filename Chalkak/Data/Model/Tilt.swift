//
//  Tilt.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

import Foundation

/// 카메라의 기울기 정보를 나타내는 구조체입니다.
struct Tilt: Codable, Hashable {
    /// 좌우균형을 나타내는 기울기 성분
    /// ## 값 범위
    /// - `-1.0`: 완전히 왼쪽으로 기울어진 상태 (90도)
    /// - `0.0`: 수평 상태 (기울기 없음)
    /// - `1.0`: 완전히 오른쪽으로 기울어진 상태 (90도)
    var degreeX: Double
    
    /// 앞뒤기울기를 나타내는 성분
    /// ## 값 범위
    /// - `-1.0`: 완전히 뒤로 기울어진 상태 (90도)
    /// - `0.0`: 수직 상태 (기울기 없음)
    /// - `1.0`: 완전히 앞으로 기울어진 상태 (90도)
    var degreeZ: Double
}

/// 특정 시점의 기울기 정보를 담고 있는 구조체입니다.
struct TimeStampedTilt: Codable {
    /// 시간 정보 (밀리초 단위).
    let time: Double
    
    /// 해당 시점의 카메라 기울기 값.
    let tilt: Tilt
}

/// 특정 시점의 카메라 높이 정보를 담고 있는 구조체입니다.
struct TimeStampedHeight: Codable {
    /// 시간 정보 (밀리초 단위).
    let time: Int64
    
    /// 해당 시점의 카메라 높이 값.
    let height: Float
}
