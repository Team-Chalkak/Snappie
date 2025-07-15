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
    // MARK: - Properties
    /// CoreMotion 데이터를 수집하는 모션 매니저
    private var motionManager = CMMotionManager()

    /// 디바이스가 좌우로 기울어진 정도
    @Published var gravityX: Double = 0.0

    /// 디바이스가 앞뒤로 기울어진 정도
    @Published var gravityZ: Double = 0.0

    // MARK: - init
    /// TiltDataCollector를 초기화하고 CoreMotion 데이터 수집을 시작합니다.
    init() {
        // 디바이스 모션 업데이트 시작
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0  // 1초에 60번(60FPS)
            motionManager.startDeviceMotionUpdates(to: .main) {
                [weak self] (data, error) in
                guard let self = self, let data = data else { return }

                self.gravityX = data.gravity.x
                self.gravityZ = data.gravity.z
            }
        }
    }
}
