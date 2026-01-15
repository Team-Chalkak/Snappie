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
 ```swift
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
    private let motionQueue = OperationQueue()

    /// 디바이스가 좌우로 기울어진 정도
    @Published var gravityX: Double = 0.0

    /// 디바이스가 앞뒤로 기울어진 정도
    @Published var gravityZ: Double = 0.0

    init() {
        motionQueue.name = "TiltMotionQueue"
        motionQueue.qualityOfService = .userInteractive
    }
    
    // 디바이스 모션 업데이트 시작
    func start() {
        guard motionManager.isDeviceMotionAvailable else { return }
        guard !motionManager.isDeviceMotionActive else { return }

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: motionQueue) { [weak self] data, _ in
            guard let self, let data else { return }

            DispatchQueue.main.async {
                self.gravityX = data.gravity.x
                self.gravityZ = data.gravity.z
            }
        }
    }
    
    func stop() {
        guard motionManager.isDeviceMotionActive else { return }
        motionManager.stopDeviceMotionUpdates()
    }
    
    /// TiltDataCollector가 해제될 때 motion updates를 자동으로 중지하도록 처리
    deinit {
        stop()
    }
}
