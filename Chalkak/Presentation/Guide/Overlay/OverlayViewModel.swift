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
    // 0. Input properties
    let clip: Clip
    
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
    init(clip: Clip) {
        self.clip = clip
        extractor.overlayManager = overlayManager
        prepareOverlay()
    }

    /// 첫번째 프레임, 오버레이 추출
    func prepareOverlay() {
        isLoading = true
        extractor.extractFrame(from: clip.videoURL, at: clip.startPoint) { [weak self] in
            DispatchQueue.main.async {
                self?.isLoading = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self?.isOverlayReady = true
                }
            }
        }
    }

    /// 시작 시점과 가장 가까운 직후의 기울기 값 추출
    private func determineTilt() -> Tilt {
        let tiltList = clip.tiltList
        let startPoint = clip.startPoint
        
        let timestampedTilt = tiltList
            .filter { $0.time >= startPoint }
            .min {
                abs($0.time - startPoint) < abs($1.time - startPoint)
            }
        
        return timestampedTilt?.tilt ?? Tilt(degreeX: 0.0, degreeZ: 0.0)
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
        guard let capturedImage = overlayManager.outlineImage else {
            print("❌ outlineImage가 없습니다.")
            return nil
        }
        // 가이드 tilt 값 결정
        let cameraTilt = determineTilt()
        
        let outlineImage: UIImage
        let savedIsFront = UserDefaults.standard.string(forKey: UserDefaultKey.cameraPosition)

        if savedIsFront == "true" {
            outlineImage = capturedImage.flippedHorizontally()
        } else {
            outlineImage = capturedImage
        }
        
        // 여러 BoundingBox → BoundingBoxInfo 배열로 변환
            let boundingBoxInfos: [BoundingBoxInfo] = overlayManager.boundingBoxes.map { box in
                BoundingBoxInfo(
                    origin: PointWrapper(box.origin),
                    scale: box.width // 필요 시 width/height 따로 둘 수도 있음
                )
            }
        
        let guide = SwiftDataManager.shared.createGuide(
            clipID: clipID,
            boundingBoxes: boundingBoxInfos,
            outlineImage: outlineImage,
            cameraTilt: cameraTilt,
            cameraHeight: 1.0
        )
        
        if let projectID = UserDefaults.standard.string(forKey: "currentProjectID") {
            SwiftDataManager.shared.saveGuideToProject(projectID: projectID, guide: guide)
        }
        return guide
    }
    
    /// 커버이미지(첫 클립 첫 프레임 이미지(extractedImage)) Project에 저장
    @MainActor
    func saveCoverImageToProject() {
        if let projectID = UserDefaults.standard.string(forKey: "currentProjectID"),
           let cover = extractedImage {
            SwiftDataManager.shared.updateProjectCoverImage(
                projectID: projectID,
                coverImage: cover
            )
        }
    }
}
