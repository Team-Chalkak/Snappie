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

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectHumanRectanglesRequest { [weak self] req, _ in
            guard let results = req.results as? [VNHumanObservation] else {
                DispatchQueue.main.async {
                    self?.onMultiBoundingBoxUpdate?([])
                }
                return
            }

            let boxes = results.map { $0.boundingBox }
            DispatchQueue.main.async {
                self?.onMultiBoundingBoxUpdate?(boxes)
            }
        }

        request.upperBodyOnly = false

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: .right,
                                            options: [:])
        try? handler.perform([request])
    }
}
