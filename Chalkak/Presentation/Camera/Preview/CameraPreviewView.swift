//
//  CameraPreview.swift
//  Chalkak
//
//  Created by 정종문 on 7/13/25.
//
import AVFoundation
import SwiftUI

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    @Binding var showGrid: Bool
    let tabToFocus: ((CGPoint) -> Void)?
    
    class VideoPreviewView: UIView {
        var gridLayer: CAShapeLayer?
        var handleFocus: ((CGPoint) -> Void)?
        
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            
            // 터치포인트 카메라 좌표 변환
            let devicePoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: location)
            
            showFocusBox(at: location)
            
            handleFocus?(devicePoint)
        }
        
        // focusbox 표시
        private func showFocusBox(at point: CGPoint) {
            // 기존에 있던 focusbox 제거
            layer.sublayers?.forEach { sublayer in
                if sublayer.name == "focusBox" {
                    sublayer.removeFromSuperlayer()
                }
            }
            
            // focus박스 생성
            let focusBoxLayer = CAShapeLayer()
            focusBoxLayer.name = "focusBox"
            focusBoxLayer.strokeColor = UIColor.yellow.cgColor
            focusBoxLayer.fillColor = UIColor.clear.cgColor
            focusBoxLayer.lineWidth = 2.0
            
            let boxSize: CGFloat = 60
            let boxRect = CGRect(
                x: point.x - boxSize / 2,
                y: point.y - boxSize / 2,
                width: boxSize,
                height: boxSize
            )
            
            let path = UIBezierPath(rect: boxRect)
            focusBoxLayer.path = path.cgPath
            
            focusBoxLayer.opacity = 0
            layer.addSublayer(focusBoxLayer)
            
            // 박스레이어 fadein
            let fadeIn = CABasicAnimation(keyPath: "opacity")
            fadeIn.fromValue = 0
            fadeIn.toValue = 1
            fadeIn.duration = 0.2
            focusBoxLayer.add(fadeIn, forKey: "fadeIn")
            focusBoxLayer.opacity = 1
            
            // 2초뒤사라짐
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                let fadeOut = CABasicAnimation(keyPath: "opacity")
                fadeOut.fromValue = 1
                fadeOut.toValue = 0
                fadeOut.duration = 0.3
                focusBoxLayer.add(fadeOut, forKey: "fadeOut")
                focusBoxLayer.opacity = 0
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    focusBoxLayer.removeFromSuperlayer()
                }
            }
        }
        
        func showGrid() {
            // 기존 그리드레이어 제거
            gridLayer?.removeFromSuperlayer()
            // 그리드 레이어 새로 그리기
            let gridShapeLayer = CAShapeLayer()
            gridShapeLayer.strokeColor = UIColor.white.withAlphaComponent(0.3).cgColor
            gridShapeLayer.lineWidth = 0.5
            gridShapeLayer.fillColor = UIColor.clear.cgColor
            
            // 베젤빼고 정말 촬영중인 그 비디어 프레임 계산
            let videoRect = videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: CGRect(x: 0, y: 0, width: 1, height: 1))
            
            let path = UIBezierPath()
            
            // 세로선
            let verticalSpacing = videoRect.width / 3
            for i in 1..<3 {
                let x = videoRect.origin.x + CGFloat(i) * verticalSpacing
                path.move(to: CGPoint(x: x, y: videoRect.origin.y))
                path.addLine(to: CGPoint(x: x, y: videoRect.origin.y + videoRect.height))
            }
            
            // 가로선
            let horizontalSpacing = videoRect.height / 3
            for i in 1..<3 {
                let y = videoRect.origin.y + CGFloat(i) * horizontalSpacing
                path.move(to: CGPoint(x: videoRect.origin.x, y: y))
                path.addLine(to: CGPoint(x: videoRect.origin.x + videoRect.width, y: y))
            }
            
            gridShapeLayer.path = path.cgPath
            layer.addSublayer(gridShapeLayer)
            gridLayer = gridShapeLayer
        }
        
        func hideGrid() {
            gridLayer?.removeFromSuperlayer()
            gridLayer = nil
        }
    }
   
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        
        view.videoPreviewLayer.session = session
        view.backgroundColor = .black
        view.videoPreviewLayer.videoGravity = .resizeAspect
        view.videoPreviewLayer.cornerRadius = 0
        view.videoPreviewLayer.connection?.videoRotationAngle = 90
        view.handleFocus = tabToFocus

        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        showGrid ? uiView.showGrid() : uiView.hideGrid()
    }
}
