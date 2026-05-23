//
//  Untitled.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

import AVFoundation
import Vision

class BoundingBoxManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onMultiBoundingBoxUpdate: (([CGRect]) -> Void)?

    private var frameCounter = 0
    /// 매 N프레임마다 한 번씩만 인식 (30fps 입력 → ≈10fps 인식)
    /// 촬영/프리뷰 프레임에는 영향 없음
    private let frameInterval = 3

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        frameCounter &+= 1
        guard frameCounter % frameInterval == 0 else { return }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: .right,
                                            options: [:])
        do {
            try handler.perform([request])

            guard let result = request.results?.first as? VNInstanceMaskObservation else {
                DispatchQueue.main.async { [weak self] in
                    self?.onMultiBoundingBoxUpdate?([])
                }
                return
            }

            let maskedBuffer = try result.generateMaskedImage(
                ofInstances: result.allInstances,
                from: handler,
                croppedToInstancesExtent: false
            )

            let boxes: [CGRect]
            if let unionBox = unionBoundingBox(fromMaskedBuffer: maskedBuffer) {
                boxes = [unionBox]
            } else {
                boxes = []
            }

            DispatchQueue.main.async { [weak self] in
                self?.onMultiBoundingBoxUpdate?(boxes)
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.onMultiBoundingBoxUpdate?([])
            }
        }
    }
}
