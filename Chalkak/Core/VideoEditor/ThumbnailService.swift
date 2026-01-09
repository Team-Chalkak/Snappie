//
//  ThumbnailService.swift
//  Chalkak
//
//  Created by bishoe01 on 1/9/26.
//

import AVFoundation
import UIKit

final class ThumbnailService {
    private var imageGenerator: AVAssetImageGenerator?
    private let thumbnailCount = 10

    /// ImageGenerator 초기화로직
    func setupImageGenerator(asset: AVAsset) {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        imageGenerator = generator
    }

    /// (영상 전체 길이 / 썸네일 간격 ) - 썸네일 이미지 생성
    @MainActor
    func generateThumbnails(duration: Double) async -> [UIImage] {
        guard let imageGenerator = imageGenerator else { return [] }
        var thumbnails: [UIImage] = []
        let interval = duration / Double(thumbnailCount)

        let times = (0 ..< thumbnailCount).map { i in
            CMTime(seconds: Double(i) * interval, preferredTimescale: 600)
        }

        do {
            for try await result in imageGenerator.images(for: times) {
                let cgImage = try result.image
                let uiImage = UIImage(cgImage: cgImage)
                thumbnails.append(uiImage)
            }
        } catch {
            print("Thumbnail error: \(error)")
        }

        return thumbnails
    }

    /// 특정 시간의 프레임을 추출 - 프리뷰 이미지 생성
    @MainActor
    func updatePreviewImage(at time: Double, trimOffset: Double) async -> UIImage? {
        guard let imageGenerator = imageGenerator else { return nil }

        let actualTime = time + trimOffset
        let cmTime = CMTime(seconds: actualTime, preferredTimescale: 600)
        do {
            let result = try await imageGenerator.image(at: cmTime)
            return UIImage(cgImage: result.image)
        } catch {
            print(error)
            return nil
        }
    }

    /// 트리밍된 구간의 썸네일 생성
    @MainActor
    func generateTrimmedThumbnails(
        trimStart: Double,
        trimEnd: Double
    ) async -> [UIImage] {
        guard let imageGenerator = imageGenerator else { return [] }
        var thumbnails: [UIImage] = []
        let trimmedDuration = trimEnd - trimStart
        let interval = trimmedDuration / Double(thumbnailCount)

        let times = (0 ..< thumbnailCount).map { i in
            CMTime(seconds: trimStart + Double(i) * interval, preferredTimescale: 600)
        }

        do {
            for try await result in imageGenerator.images(for: times) {
                let cgImage = try result.image
                let uiImage = UIImage(cgImage: cgImage)
                thumbnails.append(uiImage)
            }
        } catch {
            print("썸네일트리밍 error \(error)")
        }

        return thumbnails
    }
}
