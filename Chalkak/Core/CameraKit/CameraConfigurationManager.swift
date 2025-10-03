//
//  CameraConfigurationManager.swift
//  Chalkak
//
//  Created by bishoe01 on 10/3/25.
//

import AVFoundation
import SwiftUI

class CameraConfigurationManager: ObservableObject {
    /// 모든 카메라 설정을 한 번의 lockForConfiguration으로 처리
    func configureCameraSettings(for device: AVCaptureDevice, zoomScale: CGFloat) throws {
        // 최적 포맷찾기 lock이전에 미리 계산)
        let bestFormat = findBestFormat(for: device)

        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }

        // 포맷 설정
        if let format = bestFormat {
            device.activeFormat = format
        }

        // fps설정
        let supportedRanges = device.activeFormat.videoSupportedFrameRateRanges
        let supports60fps = supportedRanges.contains { $0.maxFrameRate >= 60 }
        let fps = supports60fps ? 60 : 30
        let frameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))
        device.activeVideoMinFrameDuration = frameDuration
        device.activeVideoMaxFrameDuration = frameDuration

        // 초점 설정
        if device.isSmoothAutoFocusSupported {
            device.isSmoothAutoFocusEnabled = true
        }
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }
        /// 자동 조정 모드 설정
        ///  - .none = 제한 없음 (가까운 곳~먼 곳 다 초점 가능)
        ///  - .near = 가까운 곳만 초점
        ///  - .far = 먼 곳만 초점
        if device.isAutoFocusRangeRestrictionSupported {
            device.autoFocusRangeRestriction = .none
        }

        // 노출 설정
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }

        // 줌 설정
        let minZoom = device.minAvailableVideoZoomFactor
        let maxZoom = device.maxAvailableVideoZoomFactor
        let zoomFactorToSet = zoomScale * 2.0
        let clampedZoomFactor = max(minZoom, min(zoomFactorToSet, maxZoom))
        device.videoZoomFactor = clampedZoomFactor
    }

    /// 60fps 지원 최적 포맷 찾기 (lockForConfiguration전에 미리 계산 - 충돌방지)
    private func findBestFormat(for device: AVCaptureDevice) -> AVCaptureDevice.Format? {
        var bestFormat: AVCaptureDevice.Format?
        var maxResolution: Int32 = 0

        // 1080p제한 (1920x1080 = 2073600)
        let maxAllowedResolution: Int32 = 2_073_600
        // 높은 해상도기준 정렬
        let sortedFormats = device.formats.sorted { format1, format2 in
            let dim1 = CMVideoFormatDescriptionGetDimensions(format1.formatDescription)
            let dim2 = CMVideoFormatDescriptionGetDimensions(format2.formatDescription)
            let res1 = dim1.width * dim1.height
            let res2 = dim2.width * dim2.height
            return res1 > res2
        }

        // 최적 포맷(1080p,60fps)에 근접할 수 있게 탐색
        for format in sortedFormats {
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let currentResolution = dimensions.width * dimensions.height

            // 1080p 이하인지 확인
            guard currentResolution <= maxAllowedResolution else { continue }

            if currentResolution <= maxResolution { continue }

            let supports60fps = format.videoSupportedFrameRateRanges.contains { range in
                range.maxFrameRate >= 60
            }

            if supports60fps {
                bestFormat = format
                maxResolution = currentResolution
                // 최고 해상도 -> 조기 종료
                break
            }
        }

        return bestFormat
    }
}
