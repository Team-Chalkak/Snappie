//
//  TorchMode.swift
//  Chalkak
//
//  Created by 정종문 on 7/21/25.
//

/// 카메라 토치 모드(플래시) 정의
///
/// 카메라의 토치 동작을 세 가지 모드
/// - off: 토치가 꺼진 상태
/// - on: 토치가 항상 켜진 상태
/// - auto: 자동으로 토치가 조절되는 상태 (주변 밝기에 따라 자동으로 토치 조절)
enum TorchMode: CaseIterable {
    case off, on, auto

    mutating func toggle() {
        switch self {
        case .off: self = .on
        case .on: self = .auto
        case .auto: self = .off
        }
    }

    var iconName: String {
        switch self {
        case .off: return "bolt.slash"
        case .on: return "bolt.fill"
        case .auto: return "bolt.badge.automatic"
        }
    }
}
