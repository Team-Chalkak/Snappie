//
//  CameraHeightManager.swift
//  Chalkak
//
//  Created by 석민솔 on 7/9/25.
//

import Foundation

/// AR 기반 높이 측정 및 UI 상태를 관리하는 클래스
///
/// 이 클래스는 ARKit에서 측정된 높이 데이터를 받아 비즈니스 로직을 처리하고,
/// UI에 필요한 상태값들을 계산하여 제공합니다.
///
/// ## 주요 기능
/// - 실시간 높이 측정 데이터 처리
/// - 바닥 감지 상태 관리
///
/// ## 사용법
/// ```swift
/// @StateObject private var heightManager = HeightManager()
///
/// HeightMeasurementARView(
///     measuredHeight: $heightManager.measuredHeight,
///     isGroundFound: $heightManager.isGroundFound
/// )
/// ```
///
class HeightManager: ObservableObject {
    
    /// AR 원점이 바닥을 기준으로 설정되었는지 확인하는 변수
    ///
    /// 이 값이 `true`가 되면 ARKit이 바닥 평면을 성공적으로 감지했음을 의미하며,
    /// 높이 측정이 시작될 수 있습니다.
    @Published var isGroundFound: Bool = false

    /// 측정된 높이를 저장하는 상태 변수 (미터 단위)
    @Published var measuredHeight: Float = 0
}
