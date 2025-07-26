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
    let tabToFocus: ((CGPoint) -> Void)?
    let onPinchZoom: ((CGFloat) -> Void)?
    let currentZoomScale: CGFloat
    let isUsingFrontCamera: Bool
    @Binding var showGrid: Bool
    let isTimerRunning: Bool
    let timerCountdown: Int
    
    class VideoPreviewView: UIView {
        var gridLayer: CAShapeLayer?
        var countdownLabel: UILabel?
        var handleFocus: ((CGPoint) -> Void)?
        var handlePinchZoom: ((CGFloat) -> Void)?
        var isUsingFrontCamera: Bool = false
        
        private var initialZoomScale: CGFloat = 1.0
        private var lastPinchScale: CGFloat = 1.0
        
        func updateInitialZoomScale(_ scale: CGFloat) {
            initialZoomScale = scale
        }
        
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
        
        func setupGestures() {
            let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
            addGestureRecognizer(pinchGesture)
        }
        
        @objc private func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
            // 전면 카메라일 때는 핀치 제스처를 무시
            if isUsingFrontCamera {
                return
            }
            
            // 감도 개선- 줌스케일 10%로 제한
            let zoomSensitivity: CGFloat = 0.1
            // 감도기반 줌스케일 보정값 적용
            let adjustScale = 1.0 + (gesture.scale - 1.0) * zoomSensitivity
            switch gesture.state {
            case .began:
                lastPinchScale = gesture.scale
            case .changed:
                let newZoomScale = initialZoomScale * adjustScale
                // 줌 범위 제한
                let clampedZoomScale = max(0.5, min(6.0, newZoomScale))
                handlePinchZoom?(clampedZoomScale)
            case .ended:
                initialZoomScale = max(0.5, min(6.0, initialZoomScale * adjustScale))
                gesture.scale = 1.0
            default:
                break
            }
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
            focusBoxLayer.strokeColor = UIColor(SnappieColor.primaryNormal).withAlphaComponent(0.3).cgColor
            focusBoxLayer.fillColor = UIColor.clear.cgColor
            focusBoxLayer.lineWidth = 1.0
            
            // dropshadow 효과
            focusBoxLayer.shadowColor = UIColor.black.cgColor
            focusBoxLayer.shadowOpacity = 0.25
            focusBoxLayer.shadowOffset = CGSize(width: 0, height: 0)
            focusBoxLayer.shadowRadius = 2
            
            // 박스 초기 86 -> 초점박스 72
            let initialSize: CGFloat = 86
            let finalSize: CGFloat = 72
            
            let initialRect = CGRect(
                x: point.x - initialSize / 2,
                y: point.y - initialSize / 2,
                width: initialSize,
                height: initialSize
            )
            
            let initialPath = UIBezierPath(ovalIn: initialRect)
            focusBoxLayer.path = initialPath.cgPath
            
            focusBoxLayer.opacity = 0
            layer.addSublayer(focusBoxLayer)
            
            // 최종 경로 생성
            let finalRect = CGRect(
                x: point.x - finalSize / 2,
                y: point.y - finalSize / 2,
                width: finalSize,
                height: finalSize
            )
            let finalPath = UIBezierPath(ovalIn: finalRect)
            
            // 애니메이션 그룹 생성
            let animationGroup = CAAnimationGroup()
            animationGroup.duration = 0.25
            animationGroup.fillMode = .forwards
            animationGroup.isRemovedOnCompletion = false
            animationGroup.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            // 크기 변화 86 -> 72
            let pathAnimation = CABasicAnimation(keyPath: "path")
            pathAnimation.fromValue = initialPath.cgPath
            pathAnimation.toValue = finalPath.cgPath
            
            // 투명도 애니메이션
            let opacityAnimation = CABasicAnimation(keyPath: "opacity")
            opacityAnimation.fromValue = 1.0
            opacityAnimation.toValue = 1.0
            
            // 포커스박스 border 투명도 30% -> 100%
            let colorAnimation = CABasicAnimation(keyPath: "strokeColor")
            colorAnimation.fromValue = UIColor(SnappieColor.primaryNormal).withAlphaComponent(0.3).cgColor
            colorAnimation.toValue = UIColor(SnappieColor.primaryNormal).cgColor
            
            animationGroup.animations = [pathAnimation, opacityAnimation, colorAnimation]
            
            focusBoxLayer.add(animationGroup, forKey: "focusAnimation")
            focusBoxLayer.opacity = 1
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            focusBoxLayer.path = finalPath.cgPath
            focusBoxLayer.strokeColor = UIColor(SnappieColor.primaryNormal).cgColor
            CATransaction.commit()
            
            // 2초 뒤 사라짐
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                let fadeOut = CABasicAnimation(keyPath: "opacity")
                fadeOut.fromValue = 1
                fadeOut.toValue = 0
                fadeOut.duration = 0.3
                fadeOut.fillMode = .forwards
                fadeOut.isRemovedOnCompletion = false
                focusBoxLayer.add(fadeOut, forKey: "fadeOut")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    focusBoxLayer.removeFromSuperlayer()
                }
            }
        }
        
        func showGrid() {
            // 기존 그리드 제거
            gridLayer?.removeFromSuperlayer()
            // 그리드 레이어 새로 그리기
            let gridShapeLayer = CAShapeLayer()
            gridShapeLayer.strokeColor = UIColor(SnappieColor.primaryLight).cgColor
            gridShapeLayer.lineWidth = 1
            gridShapeLayer.fillColor = UIColor.clear.cgColor
            
            // 베젤빼고 정말 촬영중인 비디오 프레임 계산
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
        
        func showCountdown(_ countdown: Int) {
            // 기존 카운트다운 라벨 제거
            countdownLabel?.removeFromSuperview()
            
            // 카운트다운 라벨 생성
            let label = UILabel()
            label.text = "\(countdown)"
            label.textColor = UIColor(SnappieColor.labelPrimaryNormal)
            label.font = UIFont(name: "KronaOne-Regular", size: 164)
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            
            addSubview(label)
            
            // CameraFrame 중앙 배치
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: centerXAnchor),
                label.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
            
            countdownLabel = label
        }
        
        func hideCountdown() {
            countdownLabel?.removeFromSuperview()
            countdownLabel = nil
        }
    }
   
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        
        view.videoPreviewLayer.session = session
        view.backgroundColor = .black
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.videoPreviewLayer.cornerRadius = 24
        view.videoPreviewLayer.connection?.videoRotationAngle = 90
        view.handleFocus = tabToFocus
        view.handlePinchZoom = onPinchZoom
        // 핀치 제스처
        view.setupGestures()

        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        showGrid ? uiView.showGrid() : uiView.hideGrid()
        
        // 카운트다운
        if isTimerRunning, timerCountdown > 0 {
            uiView.showCountdown(timerCountdown)
        } else {
            uiView.hideCountdown()
        }
        
        // 외부에서 줌 스케일이 변경되었을 때 동기화
        uiView.updateInitialZoomScale(currentZoomScale)
        
        // 핀치제스처 막기위한 현재 카메라 포지션 업데이트
        uiView.isUsingFrontCamera = isUsingFrontCamera
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showGrid ? uiView.showGrid() : uiView.hideGrid()
        }
    }
}
