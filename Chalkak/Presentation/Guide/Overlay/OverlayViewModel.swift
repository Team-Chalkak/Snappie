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
    let cameraSetting: CameraSetting
    
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
    private var coverImage: Data?

    // 4. Init
    init(clip: Clip, cameraSetting: CameraSetting) {
        self.clip = clip
        self.cameraSetting = cameraSetting
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
    
    /// 시가 기반 이름 자동 생성 함수 - 날짜 Formatter
    private func generateTimeBasedTitle(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HHmm"
        let timeString = formatter.string(from: date)
        return "프로젝트 \(timeString)"
    }
    
    /// `Project` 저장
    /// 첫번째 영상 촬영 시점에 Clip 먼저 저장한 후에 해당 데이터와 nil 상태인 guide를 함께 저장
    /// ProjectID는 UserDefault에도 저장되어 있습니다.
    @MainActor
    func saveProjectData() {
        guard let clip = saveClipData() else {
            print("클립 저장에 실패했습니다.")
            return
        }
        print("클립 저장")
        
        let cameraSetting = saveCameraSetting()
        print("cameraSetting 저장")
        let guide = makeGuide(clipID: clip.id)
        print("guide 저장")
        if let originalImage = extractedImage,
           let croppedImage = croppedToSquare(image: originalImage) {
            coverImage = croppedImage.jpegData(compressionQuality: 0.8)
        }
        print("coverImage 저장")

        let projectID = UUID().uuidString
        // 프로젝트 생성 시간
        let createdAt = Date()
        
        // 프로젝트 이름 자동 생성
        let generatedTitle = generateTimeBasedTitle(from: createdAt)
        
        _ = SwiftDataManager.shared.createProject(
            id: projectID,
            guide: guide,
            clips: [clip],
            cameraSetting: cameraSetting,
            title: generatedTitle,
            referenceDuration: clip.endPoint - clip.startPoint,
            coverImage: coverImage,
            createdAt: createdAt
        )
    
        SwiftDataManager.shared.saveContext()
        UserDefaults.standard.set(projectID, forKey: "currentProjectID")
    }
    
    /// clipID를 생성하고, SwiftDataManager를 통해 SwiftData에 저장
    @MainActor
    func saveClipData() -> Clip? {
        return SwiftDataManager.shared.createClip(clip: clip)
    }
    
    @MainActor
    func saveCameraSetting() -> CameraSetting {
        return SwiftDataManager.shared.createCameraSetting(cameraSetting: cameraSetting)
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
    
    /// 정사각형 중앙 크롭 이미지 반환 함수
    func croppedToSquare(image: UIImage) -> UIImage? {
        let originalWidth  = image.size.width
        let originalHeight = image.size.height
        let sideLength = min(originalWidth, originalHeight)

        let originX = (originalWidth - sideLength) / 2.0
        let originY = (originalHeight - sideLength) / 2.0

        let cropRect = CGRect(x: originX, y: originY, width: sideLength, height: sideLength)

        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return nil
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
