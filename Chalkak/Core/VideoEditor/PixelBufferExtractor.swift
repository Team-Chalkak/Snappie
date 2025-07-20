//
//  PixelBufferExtractor.swift
//  Chalkak
//
//  Created by 배현진 on 7/21/25.
//

import AVFoundation

final class PixelBufferExtractor {
    static func extractPixelBuffer(from url: URL, at time: CMTime) async throws -> CVPixelBuffer {
        let asset = AVAsset(url: url)

        // 트랙 찾기
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw NSError(domain: "PixelBufferExtractor", code: 1, userInfo: [NSLocalizedDescriptionKey: "비디오 트랙을 찾을 수 없습니다."])
        }

        // Reader 구성
        let reader = try AVAssetReader(asset: asset)
        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]

        let readerOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        readerOutput.alwaysCopiesSampleData = false
        reader.add(readerOutput)

        // 타겟 시점으로 이동
        reader.timeRange = CMTimeRange(start: time, duration: CMTimeMake(value: 1, timescale: 30))

        guard reader.startReading() else {
            throw NSError(domain: "PixelBufferExtractor", code: 2, userInfo: [NSLocalizedDescriptionKey: "AVAssetReader 시작 실패"])
        }

        // 샘플 버퍼에서 pixelBuffer 추출
        while reader.status == .reading {
            if let sampleBuffer = readerOutput.copyNextSampleBuffer(),
               let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                return pixelBuffer
            }
        }

        // 실패 시
        throw NSError(domain: "PixelBufferExtractor", code: 3, userInfo: [NSLocalizedDescriptionKey: "pixelBuffer를 찾을 수 없습니다."])
    }
}
