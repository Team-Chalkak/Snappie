//
//  OverlayViewModel.swift
//  Chalkak
//
//  Created by Youbin on 7/15/25.
//

import Foundation
import UIKit

/// 실루엣 오버레이(윤곽선) 추출 및 저장 관련 뷰모델
final class OverlayViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var isOverlayReady = false

    let extractor = VideoFrameExtractor()
    let overlayManager = OverlayManager()

    var outlineImage: UIImage? { overlayManager.outlineImage }
    var extractedImage: UIImage? { extractor.extractedImage }

    init() {
        extractor.overlayManager = overlayManager
    }

    func prepareOverlay(from url: URL, at time: Double) {
        isLoading = true
        extractor.extractFrame(from: url, at: time) { [weak self] in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.isOverlayReady = true
            }
        }
    }

    func dismissOverlay() {
        isOverlayReady = false
        isLoading = false
        overlayManager.outlineImage = nil
        overlayManager.maskedCIImage = nil
        overlayManager.maskedUIImage = nil
        extractor.extractedImage = nil
        extractor.extractedCIImage = nil
    }

    func createGuideForLog() {
        guard let outlineImage = overlayManager.outlineImage,
              let bBox = overlayManager.boundingBox else {
            print("❌ 로그 출력을 위한 정보가 부족합니다.")
            return
        }
        let guide = Guide(
            clipID: "dummy-id",
            bBoxPosition: bBox.origin,
            bBoxScale: bBox.width,
            outlineImage: outlineImage,
            cameraTilt: Tilt(degreeX: 0, degreeZ: 0),
            cameraHeight: 1.0
        )
        print("--- GUIDE ---")
        print("\(guide)")
    }
}
