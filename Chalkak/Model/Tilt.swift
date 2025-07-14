//
//  Tilt.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

import Foundation

/// 카메라의 기울기 정보를 나타내는 구조체입니다.
struct Tilt: Codable, Hashable {
    /// X축 방향 기울기 각도.
    var degreeX: Double
    
    /// Z축 방향 기울기 각도.
    var degreeZ: Double
}

/// 특정 시점의 기울기 정보를 담고 있는 구조체입니다.
struct TimeStampedTilt: Codable {
    /// 시간 정보 (밀리초 단위).
    let time: Int64
    
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
