//
//  OverlayManager.swift
//  Chalkak
//
//  Created by Youbin on 7/15/25.
//

import Vision
import CoreImage
import UIKit
import CoreImage.CIFilterBuiltins

/// 사람 인식 및 실루엣 오버레이 추출
class OverlayManager: ObservableObject {
    /// 바운딩 박스, CIImage 객체
    @Published var boundingBox: CGRect?
    @Published var maskedCIImage: CIImage?
    @Published var maskedUIImage: UIImage? /// 누끼 따는 것 잘 되었는지 테스트용

    /// 윤곽선 객체
    @Published var outlineImage: UIImage?  // 윤곽선 이미지
    @Published var shadowImage: UIImage?

    private let context = CIContext()

    // 2~4단계 통합 처리
    func process(image: CIImage, completion: @escaping () -> Void) {
        // 1. 요청 생성
        let rectangleRequest = VNDetectHumanRectanglesRequest()
        let maskRequest = VNGenerateForegroundInstanceMaskRequest()

        let handler = VNImageRequestHandler(ciImage: image, options: [:])

        DispatchQueue.global().async {
            do {
                try handler.perform([rectangleRequest, maskRequest])

                // 2단계: BoundingBox 추출
                if let result = rectangleRequest.results?.first as? VNHumanObservation {
                    DispatchQueue.main.async {
                        self.boundingBox = result.boundingBox
                    }
                }

                // 3단계: 마스크 생성
                guard let maskResult = maskRequest.results?.first as? VNInstanceMaskObservation else {
                    print("❌ 마스크 결과 없음")
                    DispatchQueue.main.async { completion() }
                    return
                }

                // 4단계: 마스크된 이미지 생성
                let maskedPixelBuffer = try maskResult.generateMaskedImage(
                    ofInstances: maskResult.allInstances,
                    from: handler,
                    croppedToInstancesExtent: false
                )
                let ciImage = CIImage(cvPixelBuffer: maskedPixelBuffer)

                DispatchQueue.main.async {
                    self.maskedCIImage = ciImage

                    // ✅ CIImage → UIImage 변환 -> 테스트용!
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

    func applyOutlineEffect(completion: @escaping () -> Void) {
        guard let inputImage = maskedCIImage else { 
            completion()
            return 
        }

        // CIImage → CGImage
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

        // RGBA 투명 배경 비트맵 컨텍스트 생성
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

        // 투명 배경
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))

        // 빨간색 윤곽선
        context.setStrokeColor(UIColor.red.cgColor)
        context.setLineWidth(1)

        // 경계 픽셀 검사
        for y in 1..<height - 1 {
            for x in 1..<width - 1 {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let alpha = data[offset + 3]

                // 주변 픽셀들과 비교
                let neighborAlphas = [
                    data[offset - bytesPerRow + 3],  // 위
                    data[offset + bytesPerRow + 3],  // 아래
                    data[offset - bytesPerPixel + 3], // 왼쪽
                    data[offset + bytesPerPixel + 3]  // 오른쪽
                ]

                if neighborAlphas.contains(where: { abs(Int($0) - Int(alpha)) > 10 }) {
                    context.stroke(CGRect(x: x, y: height - y, width: 1, height: 1)) // y좌표 보정
                }
            }
        }

        // 이미지 생성
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
