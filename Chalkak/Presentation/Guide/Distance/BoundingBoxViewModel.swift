//
//  BoundingBoxViewModel.swift
//  Chalkak
//
//  Created by 배현진 on 7/14/25.
//

import Foundation

class BoundingBoxViewModel: ObservableObject {
    @Published var liveBoundingBoxes: [CGRect] = []
    @Published var referenceBoundingBoxes: [CGRect] = []
    @Published var isSettingReference: Bool = false
    @Published var isAligned: Bool = false
    @Published var tiltManager: CameraTiltManager?
    
    // MARK: - init
    init(properTilt: Tilt? = nil, tiltDataCollector: TiltDataCollector? = nil) {
        if let properTilt, let tiltDataCollector {
            self.tiltManager = CameraTiltManager(properTilt: properTilt, dataCollector: tiltDataCollector)
        }
    }
    
    /// 기준 설정
    func setReference(from guide: Guide) {
        let referenceBoxes: [CGRect] = guide.boundingBoxes.map { boxInfo in
            CGRect(
                x: boxInfo.origin.x,
                y: boxInfo.origin.y,
                width: boxInfo.scale,
                height: boxInfo.scale // or use separate width/height if needed
            )
        }

        referenceBoundingBoxes = referenceBoxes
        isSettingReference = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isSettingReference = false
        }
    }
    
    /// 값 비교
    func compare() {
        guard !referenceBoundingBoxes.isEmpty else { return }

        guard let ref = referenceBoundingBoxes.average(),
              let live = liveBoundingBoxes.average(),
              live.width > 0.01, live.height > 0.01 else {
            isAligned = false
            return
        }

        isAligned = isLiveBoxAligned(with: ref, live: live)
    }
    
    private func isLiveBoxAligned(with ref: CGRect, live: CGRect) -> Bool {
        let refArea = ref.width * ref.height
        let liveArea = live.width * live.height
        let ratio = liveArea / refArea

        let xDiff = abs(live.minX - ref.minX)
        let yDiff = abs(live.minY - ref.minY)

        let areaOk = (0.7...1.3).contains(ratio)
        let positionOk = (xDiff < 0.05 && yDiff < 0.05)
        
        return areaOk && positionOk
    }
}
