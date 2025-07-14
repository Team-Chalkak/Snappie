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
/// - 기준 높이와의 차이 계산
/// - UI 오프셋 자동 계산 및 범위 제한
/// - 바닥 감지 상태 관리
///
/// ## 사용법
/// ```swift
/// @StateObject private var heightManager = HeightManager(idealHeight: 1.1)
///
/// HeightMeasurementARView(
///     measuredHeight: $heightManager.measuredHeight,
///     isGroundFound: $heightManager.isGroundFound
/// )
/// ```
///
class HeightManager: ObservableObject {
    // MARK: - Properties
    /// AR 원점이 바닥을 기준으로 설정되었는지 확인하는 변수
    ///
    /// 이 값이 `true`가 되면 ARKit이 바닥 평면을 성공적으로 감지했음을 의미하며,
    /// 높이 측정이 시작될 수 있습니다.
    @Published var isGroundFound: Bool = false

    /// 측정된 높이를 저장하는 상태 변수 (미터 단위)
    ///
    /// ARKit에서 측정된 실제 높이 값이 설정되며, 값이 변경될 때마다
    /// `offsetY`가 자동으로 재계산됩니다.
    ///
    /// ## 동작 과정
    /// 1. ARKit에서 새로운 높이 값 수신
    /// 2. `didSet`에서 기준 높이와의 차이 계산
    /// 3. UI 표시용 `offsetY` 값 업데이트
    ///
    /// ## 계산 공식
    /// ```
    /// offsetY = (measuredHeight - idealHeight) * -1 * 100
    /// ```
    ///
    /// - 부호 반전(-1): UI 표시 방향 조정
    /// - 100 곱하기: 미터를 센티미터로 변환
    @Published var measuredHeight: Float = 0 {
        didSet {
            // UI에 반영될 수 있도록 -+ 반전, m단위 -> cm 단위로
            offsetY = (measuredHeight - idealHeight) * -1 * 100
        }
    }


    /// 기준 높이 (미터 단위)
    ///
    /// 사용자가 서 있어야 하는 이상적인 높이값입니다.
    /// 이 값을 기준으로 현재 높이와의 차이를 계산합니다.
    let idealHeight: Float

    /// UI 표시용 오프셋 값 (센티미터 단위)
    ///
    /// 기준 높이와 현재 높이의 차이를 UI에 표시하기 위한 값입니다.
    /// 양수는 기준보다 높음을, 음수는 기준보다 낮음을 의미합니다.
    ///
    /// ## 값 범위
    /// - 최소값: -90cm (기준보다 90cm 낮음)
    /// - 최대값: +90cm (기준보다 90cm 높음)
    ///
    @Published var offsetY: Float = 0 {
        didSet {
            // 범위 안에 들어오도록 설정
            if offsetY < -90 {
                offsetY = -90
            } else if offsetY > 90 {
                offsetY = 90
            }
        }
    }
    
    // MARK: - init
    init(idealHeight: Float) {
        self.idealHeight = idealHeight
    }
}
