//
//  MaskBoundingBox.swift
//  Chalkak
//
//  Created by bishoe01 on 23/5/26.
//  VNGenerateForegroundInstanceMaskRequest로 생성된 마스크 이미지의
//  union bounding box를 계산하는 공용 유틸
//

import CoreVideo
import Foundation

/// 마스크된 BGRA 이미지의 알파 채널에서 non-zero 픽셀 합집합 영역을
/// Vision 정규화 좌표(원점 좌하단)로 반환
func unionBoundingBox(fromMaskedBuffer maskedBuffer: CVPixelBuffer) -> CGRect? {
    let width = CVPixelBufferGetWidth(maskedBuffer)
    let height = CVPixelBufferGetHeight(maskedBuffer)
    let bytesPerRow = CVPixelBufferGetBytesPerRow(maskedBuffer)

    CVPixelBufferLockBaseAddress(maskedBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(maskedBuffer, .readOnly) }

    guard let base = CVPixelBufferGetBaseAddress(maskedBuffer) else { return nil }
    let bytes = base.assumingMemoryBound(to: UInt8.self)

    var minX = width
    var minY = height
    var maxX = -1
    var maxY = -1

    // BGRA 픽셀의 알파 채널(offset +3)이 0보다 크면 전경
    for y in 0..<height {
        let rowStart = y * bytesPerRow
        for x in 0..<width where bytes[rowStart + x * 4 + 3] > 0 {
            if x < minX { minX = x }
            if x > maxX { maxX = x }
            if y < minY { minY = y }
            if y > maxY { maxY = y }
        }
    }

    guard maxX >= 0, maxY >= 0 else { return nil }

    let w = CGFloat(width)
    let h = CGFloat(height)
    return CGRect(
        x: CGFloat(minX) / w,
        y: 1.0 - CGFloat(maxY + 1) / h,
        width: CGFloat(maxX - minX + 1) / w,
        height: CGFloat(maxY - minY + 1) / h
    )
}
