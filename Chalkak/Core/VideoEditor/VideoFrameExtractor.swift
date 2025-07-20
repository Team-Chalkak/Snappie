//
//  VideoFrameExtractorViewModel.swift
//  Chalkak
//
//  Created by Youbin on 7/15/25.
//

import AVFoundation
import UIKit

/**
 VideoFrameExtractor: 영상에서 프레임 이미지 추출

 AVAssetImageGenerator를 사용하여 특정 시간의 CGImage를 추출하고,
 CIImage와 UIImage 형태로 반환

 ## 주요 기능
 - 프레임 추출 (시간 지정 가능)
 - CIImage → OverlayManager에 전달하여 마스킹 및 윤곽선 처리
 - 추출 결과를 @Published 프로퍼티로 제공

 ## 사용 위치
 - OverlayViewModel 내부에서 사용
 - 호출 예시: `extractFrame(from: url, at: 1.0)`
 */
class VideoFrameExtractor: ObservableObject {
    // 1. Published Property
    @Published var extractedImage: UIImage?
    @Published var extractedCIImage: CIImage?
    
    // 2. Dependencies
    var overlayManager: OverlayManager?

    func extractFrame(from url: URL, at time: Double, completion: @escaping () -> Void) {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let targetTime = CMTime(seconds: time, preferredTimescale: 600)

        generator.generateCGImageAsynchronously(for: targetTime) { cgImage, actualTime, error in
            if let cgImage = cgImage {
                let uiImage = UIImage(cgImage: cgImage)
                let ciImage = CIImage(cgImage: cgImage)

                DispatchQueue.main.async {
                    self.extractedImage = uiImage
                    self.extractedCIImage = ciImage
                    
                    /// ✅ 오버레이 매니저로 전달
                    self.overlayManager?.process(image: ciImage, completion: completion)
                }
            } else {
                print("❌ 프레임 추출 실패:", error?.localizedDescription ?? "알 수 없는 에러")
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
}

