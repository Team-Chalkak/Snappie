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
    @Published var guide: Guide?
    @Published var showResumeAlert = false

    // MARK: - init

    init(properTilt: Tilt? = nil, tiltDataCollector: TiltDataCollector? = nil) {
        if let properTilt, let tiltDataCollector {
            self.tiltManager = CameraTiltManager(properTilt: properTilt, dataCollector: tiltDataCollector)
        }
    }

    /// 진행중이던 프로젝트 있는지 확인
    func checkResumeProject() {
        // 추가 촬영인 경우
        let isAppendingShoot = UserDefaults.standard.bool(forKey: UserDefaultKey.isAppendingFromEdit)

        guard !isAppendingShoot else {
            UserDefaults.standard.removeObject(forKey: UserDefaultKey.isAppendingFromEdit)
            UserDefaults.standard.set(nil, forKey: UserDefaultKey.currentProjectID)
            return
        }

        if UserDefaults.standard.string(forKey: UserDefaultKey.currentProjectID) != nil {
            showResumeAlert = true
        }
    }

    /// 진행중이던 프로젝트의 가이드 가져오기
    @MainActor
    func loadGuideForCurrentProject() -> Guide? {
        guard let projectID = UserDefaults.standard.string(forKey: UserDefaultKey.currentProjectID),
              let project = SwiftDataManager.shared.fetchProject(byID: projectID)
        else {
            return nil
        }
        let guide = project.guide
        return guide
    }

    /// 진행중이던 프로젝트 없애기
    func cancelResume() {
        UserDefaults.standard.removeObject(forKey: UserDefaultKey.currentProjectID)
        guide = nil
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

    func deleteUserDefault() {
        UserDefaults.standard.removeObject(forKey: UserDefaultKey.isGridOn)
        UserDefaults.standard.removeObject(forKey: UserDefaultKey.zoomScale)
        UserDefaults.standard.removeObject(forKey: UserDefaultKey.timerSecond)
        UserDefaults.standard.removeObject(forKey: UserDefaultKey.isFrontPosition)
        UserDefaults.standard.removeObject(forKey: UserDefaultKey.cameraPosition)
    }

    /// 값 비교
    func compare() {
        guard !referenceBoundingBoxes.isEmpty else { return }

        guard let ref = referenceBoundingBoxes.average(),
              let live = liveBoundingBoxes.average(),
              live.width > 0.01, live.height > 0.01
        else {
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

        let areaOk = (0.7 ... 1.3).contains(ratio)
        let positionOk = (xDiff < 0.05 && yDiff < 0.05)

        return areaOk && positionOk
    }
}
