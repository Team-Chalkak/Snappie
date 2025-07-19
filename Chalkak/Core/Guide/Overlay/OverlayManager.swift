//
//  OverlayManager.swift
//  Chalkak
//
//  Created by Youbin on 7/15/25.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

/**
 OverlayManager: 영상에서 사람 윤곽선 오버레이를 추출하는 유틸리티

 Vision 프레임워크를 활용하여 사람의 바운딩 박스를 탐지하고, 전경 마스크 기반으로 윤곽선을 추출
 최종적으로 윤곽선 UIImage를 만들어 OverlayView에 전달

 ## 주요 기능
 - Vision 기반 바운딩 박스, 전경 마스크 요청 처리
 - 마스킹된 CIImage → 윤곽선 그리기(CGContext)
 - outlineImage, maskedCIImage, boundingBox 등 제공

 ## 사용 위치
 - OverlayViewModel 및 VideoFrameExtractor와 연동됨
 - 사용 예시: `overlayManager.process(image: ciImage)`
 */
class OverlayManager: ObservableObject {
    // 1. Published properties
    @Published var boundingBox: CGRect?
    @Published var maskedCIImage: CIImage?
    @Published var maskedUIImage: UIImage?
    @Published var outlineImage: UIImage?
    @Published var shadowImage: UIImage?

    // 2. Private 저장 프로퍼티
    private let context = CIContext()

    //MARK: - 인물 마스킹
    /// 영상에서 사람의 마스킹하여 추출 -> outlineImage로 변환
    /// - Parameters:
    ///   - image: 입력 원본 CIImage (주로 영상 프레임)
    func process(image: CIImage, completion: @escaping () -> Void) {
        // 1. Vision 요청 준비
        let rectangleRequest = VNDetectHumanRectanglesRequest()
        let maskRequest = VNGenerateForegroundInstanceMaskRequest()

        let handler = VNImageRequestHandler(ciImage: image, options: [:])

        DispatchQueue.global().async {
            do {
                try handler.perform([rectangleRequest, maskRequest])

                /// 2단계: BoundingBox 추출
                if let results = rectangleRequest.results as? [VNHumanObservation], !results.isEmpty {
                    let boxes = results.map { $0.boundingBox }
                    let averageBox = boxes.average() // ⬅️ 이미 ViewModel에서 사용하던 확장 활용

                    DispatchQueue.main.async {
                        self.boundingBox = averageBox
                    }
                }

                /// 3단계: 마스크 생성
                guard let maskResult = maskRequest.results?.first as? VNInstanceMaskObservation else {
                    print("❌ 마스크 결과 없음")
                    DispatchQueue.main.async { completion() }
                    return
                }

                /// 4단계: 마스크된 이미지 생성
                let maskedPixelBuffer = try maskResult.generateMaskedImage(
                    ofInstances: maskResult.allInstances,
                    from: handler,
                    croppedToInstancesExtent: false
                )
                let ciImage = CIImage(cvPixelBuffer: maskedPixelBuffer)

                DispatchQueue.main.async {
                    self.maskedCIImage = ciImage

                    /// CIImage → UIImage 변환(테스트용)
                    if let cgImage = self.context.createCGImage(ciImage, from: ciImage.extent) {
                        self.maskedUIImage = UIImage(cgImage: cgImage)
                    }
                    
                    // 마스크 생성 후 바로 윤곽선 효과 적용
                    self.applyOutlineEffect(completion: completion)
                }

            } catch {
                print("❌ Vision 처리 실패:", error)
                DispatchQueue.main.async { completion() }
            }
        }
    }

    //MARK: - 실루엣 오버레이 이미지 생성
    ///마스크 이미지에서 경계선을 검출하여 윤곽선 이미지 생성
    func applyOutlineEffect(completion: @escaping () -> Void) {
        guard let inputImage = maskedCIImage else { 
            completion()
            return 
        }

        /// CIImage → CGImage
        guard let cgImage = context.createCGImage(inputImage, from: inputImage.extent),
              let dataProvider = cgImage.dataProvider,
              let pixelData = dataProvider.data else {
            print("❌ CGImage 변환 실패")
            completion()
            return
        }

        let width = cgImage.width
        let height = cgImage.height
        let data = CFDataGetBytePtr(pixelData)!
        let bytesPerPixel = 4
        let bytesPerRow = cgImage.bytesPerRow

        /// RGBA 투명 배경 비트맵 컨텍스트 생성
        let bitmapBytesPerRow = width * bytesPerPixel
        let bitmapData = malloc(height * bitmapBytesPerRow)
        defer { free(bitmapData) }

        guard let context = CGContext(
            data: bitmapData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bitmapBytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            print("❌ CGContext 생성 실패")
            completion()
            return
        }

        /// 투명 배경
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))

        /// 윤곽선 색상, 두께
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(1)

        /// 마스크 이미지의 알파 경계를 따라 선 그리기
        for y in 1..<height - 1 {
            for x in 1..<width - 1 {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let alpha = data[offset + 3]

                /// 주변 픽셀들과 비교(상하좌우)
                let neighborAlphas = [
                    data[offset - bytesPerRow + 3],
                    data[offset + bytesPerRow + 3],
                    data[offset - bytesPerPixel + 3],
                    data[offset + bytesPerPixel + 3]
                ]

                if neighborAlphas.contains(where: { abs(Int($0) - Int(alpha)) > 10 }) {
                    context.stroke(CGRect(x: x, y: height - y, width: 1, height: 1))
                }
            }
        }

        /// 최종 윤곽선 이미지 생성
        if let cgOutline = context.makeImage() {
            let outlineUIImage = UIImage(cgImage: cgOutline)
            DispatchQueue.main.async {
                self.outlineImage = outlineUIImage
                completion()
            }
        } else {
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}
