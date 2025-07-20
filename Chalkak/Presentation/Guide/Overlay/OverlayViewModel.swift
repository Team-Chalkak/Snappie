//
//  OverlayViewModel.swift
//  Chalkak
//
//  Created by Youbin on 7/15/25.
//

import Foundation
import UIKit

/**
 OverlayViewModel: 오버레이 가이드 생성 뷰모델

 영상의 특정 프레임에서 윤곽선 오버레이 이미지를 생성하고, Guide 객체로 저장

 ## 주요 기능
 - 영상에서 프레임 추출 및 OverlayManager 연동
 - 오버레이 준비 상태 관리 (isOverlayReady)
 - 추출된 실루엣 오버레이 이미지, 영상 첫번째 프레임 이미지 제공
 - Guide 객체 생성 및 SwiftData 저장 처리

 ## 사용 위치
 - OverlayView, OverlayDisplayView에서 사용
 - 호출 예시: `overlayViewModel.prepareOverlay(from: url, at: time)`
 */
final class OverlayViewModel: ObservableObject {
    // 1. Published properties
    @Published var isLoading = false
    @Published var isOverlayReady = false
    @Published var guide: Guide?

    // 2. Dependencies
    let extractor = VideoFrameExtractor()
    let overlayManager = OverlayManager()

    // 3. Computed properties
    var outlineImage: UIImage? { overlayManager.outlineImage }
    var extractedImage: UIImage? { extractor.extractedImage }

    // 4. Init
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
    func makeGuide(clipID: String, isFrontCamera: Bool) -> Guide? {
        guard let capturedImage = overlayManager.outlineImage, let bBox = overlayManager.boundingBox else {
            print("❌ outlineImage가 없습니다.")
            return nil
        }
        
        let outlineImage: UIImage
        
        if isFrontCamera {
            outlineImage = capturedImage.flippedHorizontally()
        } else {
            outlineImage = capturedImage
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
