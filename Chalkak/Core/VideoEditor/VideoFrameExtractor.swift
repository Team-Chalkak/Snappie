//
//  VideoFrameExtractorViewModel.swift
//  Chalkak
//
//  Created by Youbin on 7/15/25.
//

import AVFoundation
import UIKit

/// 영상에서 첫번째 프레임 추출
class VideoFrameExtractor: ObservableObject {
    @Published var extractedImage: UIImage?
    @Published var extractedCIImage: CIImage?
    
    var overlayManager: OverlayManager?  /// 연결

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

