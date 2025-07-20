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
    @Published var guide: Guide?
    
    let extractor = VideoFrameExtractor()
    let overlayManager = OverlayManager()

    var outlineImage: UIImage? { overlayManager.outlineImage }
    var extractedImage: UIImage? { extractor.extractedImage }

    init() {
        extractor.overlayManager = overlayManager
    }

    /// 첫번째 프레임, 오버레이 추출
    func prepareOverlay(from url: URL, at time: Double) {
        isLoading = true
        extractor.extractFrame(from: url, at: time) { [weak self] in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.isOverlayReady = true
            }
        }
    }

    /// 뒤로가기 버튼 누를 시, 오버레이 초기화
    func dismissOverlay() {
        isOverlayReady = false
        isLoading = false
        overlayManager.outlineImage = nil
        overlayManager.maskedCIImage = nil
        overlayManager.maskedUIImage = nil
        extractor.extractedImage = nil
        extractor.extractedCIImage = nil
    }

    /// Guide 객체 생성
    @MainActor
    func makeGuide(clipID: String) -> Guide? {
        guard let outlineImage = overlayManager.outlineImage, let bBox = overlayManager.boundingBox else {
            print("❌ outlineImage가 없습니다.")
            return nil
        }
        
        let guide = SwiftDataManager.shared.createGuide(
            clipID: clipID,
            bBoxPosition: PointWrapper(bBox.origin),
            bBoxScale: bBox.width * 1.5,
            outlineImage: outlineImage,
            cameraTilt: Tilt(degreeX: 0, degreeZ: 0),
            cameraHeight: 1.0
        )
        
        SwiftDataManager.shared.saveContext()
        
        return guide
    }
}
