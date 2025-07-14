//
//  TiltDataCollector.swift
//  Chalkak
//
//  Created by 석민솔 on 7/14/25.
//

import CoreMotion
import Foundation

/**
 CoreMotion 데이터를 수집하는 클래스
 
 `TiltDataCollector`는 디바이스의 물리적 기울기를 감지하여 중력 벡터 데이터를 수집합니다.
 
 ## 사용 예시
 ```
 @StateObject private var tiltCollector = TiltDataCollector()
 
 var body: some View {
     Text("x: \(tiltCollector.gravityX)")
     Text("z: \(tiltCollector.gravityZ)")
 }
 ```
 */
class TiltDataCollector: ObservableObject {

    /// CoreMotion 데이터를 수집하는 모션 매니저
    private var motionManager = CMMotionManager()

    /// 좌우균형을 나타내는 중력 벡터의 X 성분
    ///
    /// 디바이스가 좌우로 기울어진 정도를 나타내는 원시 데이터입니다.
    ///
    /// ## 값 범위
    /// - `-1.0`: 완전히 왼쪽으로 기울어진 상태 (90도)
    /// - `0.0`: 수평 상태 (기울기 없음)
    /// - `1.0`: 완전히 오른쪽으로 기울어진 상태 (90도)
    ///
    /// ## 데이터 소스
    /// CoreMotion의 `deviceMotion.gravity.x` 값을 직접 반영합니다.
    @Published var gravityX: Double = 0.0

    /// 앞뒤기울기를 나타내는 중력 벡터의 Z 성분
    ///
    /// 디바이스가 앞뒤로 기울어진 정도를 나타내는 원시 데이터입니다.
    ///
    /// ## 값 범위
    /// - `-1.0`: 완전히 앞으로 기울어진 상태 (90도)
    /// - `0.0`: 수직 상태 (기울기 없음)
    /// - `1.0`: 완전히 뒤로 기울어진 상태 (90도)
    ///
    /// ## 데이터 소스
    /// CoreMotion의 `deviceMotion.gravity.z` 값을 직접 반영합니다.
    @Published var gravityZ: Double = 0.0

    /// TiltDataCollector를 초기화하고 CoreMotion 데이터 수집을 시작합니다.
    ///
    /// 초기화 과정에서 다음 작업들을 수행합니다:
    /// 1. 디바이스 모션 사용 가능 여부 확인
    /// 2. 업데이트 간격을 초당 60회(60FPS)로 설정
    /// 3. 메인 큐에서 모션 업데이트 시작
    /// 4. Gravity 데이터에서 X, Z 값을 추출하여 Published 프로퍼티에 할당
    ///
    /// ## 업데이트 설정
    /// - **간격**: 초당 60회(60FPS)
    /// - **큐**: 메인 큐 (UI 업데이트에 최적화)
    /// - **데이터 타입**: Device Motion (융합 센서 데이터)
    ///
    /// ## 에러 처리
    /// - 디바이스 모션을 사용할 수 없는 경우 업데이트를 시작하지 않음
    /// - 데이터 수신 실패 시 업데이트를 건너뜀
    ///
    /// - Warning: 메모리 누수를 방지하기 위해 `weak self`를 사용합니다.
    init() {
        // 디바이스 모션 업데이트 시작
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0  // 1초에 60번
            motionManager.startDeviceMotionUpdates(to: .main) {
                [weak self] (data, error) in
                guard let self = self, let data = data else { return }

                self.gravityX = data.gravity.x
                self.gravityZ = data.gravity.z
            }
        }
    }
}
