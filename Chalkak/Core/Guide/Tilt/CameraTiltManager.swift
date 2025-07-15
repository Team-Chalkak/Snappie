//
//  CameraTiltManager.swift.swift
//  Chalkak
//
//  Created by 석민솔 on 7/14/25.
//

import Combine
import Foundation

/**
 기기의 기울기 데이터를 관리하고 UI 표시를 위한 오프셋 값을 계산하는 클래스

 `CameraTiltManager`는 `TiltDataCollector`로부터 받은 기울기 데이터를 처리하여
 사용자 정의 기준점 대비 오프셋 값을 실시간으로 계산합니다.

 ## 사용 예시
 ```swift
 let tiltDataCollector = TiltDataCollector()
 
 let tiltManager = CameraTiltManager(
     properTilt: Tilt(degreeX: 0.0, degreeZ: 0.0),
     dataCollector: dataCollector
 )
 ```

 ## 데이터 플로우
 1. CoreMotion → TiltDataCollector (`gravityX`, `gravityZ`)
 2. TiltDataCollector → CameraTiltManager (`Tilt(degreeX:degreeZ:)`)
 3. CameraTiltManager → UI (`offsetX`, `offsetZ`)

 ## 주요 기능
 - 실시간 기울기 데이터 수신 및 처리
 - 사용자 정의 기준점 대비 오프셋 계산
 - SwiftUI 뷰에서 바로 사용 가능한 `@Published` 프로퍼티 제공
 */
class CameraTiltManager: ObservableObject {
    // MARK: - Properties
    /// 기준점이 되는 기울기값
    let properTilt: Tilt
    
    /// 실시간으로 업데이트되는 기울기 값
    @Published var degreeTilt: Tilt = Tilt(degreeX: 0.0, degreeZ: 0.0) {
        didSet {
            self.offsetX = Float(degreeTilt.degreeX - properTilt.degreeX) * 100
            self.offsetZ = Float(degreeTilt.degreeZ - properTilt.degreeZ) * 100
        }
    }
        
    /// UI 표시용 좌우 오프셋 값
    @Published var offsetX: Float = 0
    
    /// UI 표시용 앞뒤 오프셋 값
    @Published var offsetZ: Float = 0
    
    /// Combine 구독을 관리하는 Set
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - init
    
    /// - Parameters:
    ///   - properTilt: 기준점이 되는 기울기값. 기본값은 (degreeX: 0.0, degreeZ: 0.0)입니다.
    ///   - dataCollector: 기울기 데이터를 제공하는 `TiltDataCollector` 인스턴스
    ///
    /// ## 중요사항
    /// - `dataCollector`는 이미 초기화되고 데이터 수집이 시작된 상태여야 합니다.
    /// - 초기 오프셋 값은 현재 기울기 값과 기준점의 차이로 계산됩니다.
    init(
        properTilt: Tilt = Tilt(degreeX: 0.0, degreeZ: 0.0),
        dataCollector: TiltDataCollector
    ) {
        self.properTilt = properTilt
        
        // TiltDataCollector의 gravity 값을 실시간으로 구독
        dataCollector.$gravityX
            .assign(to: \.degreeTilt.degreeX, on: self)
            .store(in: &cancellables)
        
        dataCollector.$gravityZ
            .assign(to: \.degreeTilt.degreeZ, on: self)
            .store(in: &cancellables)
        
        // 초기 오프셋 값 계산
        self.offsetX = Float(degreeTilt.degreeX - properTilt.degreeX) * 100
        self.offsetZ = Float(degreeTilt.degreeZ - properTilt.degreeZ) * 100
    }
}
