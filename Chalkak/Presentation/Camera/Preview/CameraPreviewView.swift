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
    let cameraManager: CameraManager
    let tabToFocus: ((CGPoint) -> Void)?
    let onPinchZoom: ((CGFloat) -> Void)?
    let currentZoomScale: CGFloat
    let isUsingFrontCamera: Bool
    @Binding var showGrid: Bool

    // MARK: - Preview UIView
    final class VideoPreviewView: UIView {
        var gridLayer: CAShapeLayer?
        var handleFocus: ((CGPoint) -> Void)?
        var handlePinchZoom: ((CGFloat) -> Void)?
        var isUsingFrontCamera: Bool = false

        private var initialZoomScale: CGFloat = 1.0
        private var lastPinchScale: CGFloat = 1.0

        // AVCaptureVideoPreviewLayer를 바로 루트 레이어로 사용
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

        // 레이아웃이 바뀔 때 그리드 재계산이 필요하므로 추적
        override func layoutSubviews() {
            super.layoutSubviews()
            // 그리드가 켜져 있으면 프레임 변동시 다시 그려줌
            if gridLayer != nil { redrawGrid() }
        }

        // 제스처
        func setupGestures() {
            isUserInteractionEnabled = true
            let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
            addGestureRecognizer(pinchGesture)
        }

        func updateInitialZoomScale(_ scale: CGFloat) {
            initialZoomScale = scale
        }

        @objc private func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
            // 전면 카메라에서는 줌 비활성
            if isUsingFrontCamera { return }

            let zoomSensitivity: CGFloat = 0.1
            let adjustScale = 1.0 + (gesture.scale - 1.0) * zoomSensitivity

            switch gesture.state {
            case .began:
                lastPinchScale = gesture.scale
            case .changed:
                let newZoomScale = initialZoomScale * adjustScale
                let clampedZoomScale = max(0.5, min(6.0, newZoomScale))
                handlePinchZoom?(clampedZoomScale)
            case .ended, .cancelled, .failed:
                initialZoomScale = max(0.5, min(6.0, initialZoomScale * adjustScale))
                gesture.scale = 1.0
            default:
                break
            }
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)

            // 미러/회전/크롭이 반영된 프리뷰 좌표계에서 디바이스 좌표로 변환
            let devicePoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: location)
            showFocusBox(at: location)
            handleFocus?(devicePoint)
        }

        // 포커스 박스
        private func showFocusBox(at point: CGPoint) {
            // 기존 박스 제거
            layer.sublayers?.filter { $0.name == "focusBox" }.forEach { $0.removeFromSuperlayer() }

            let focusBoxLayer = CAShapeLayer()
            focusBoxLayer.name = "focusBox"
            focusBoxLayer.strokeColor = UIColor(SnappieColor.primaryNormal).withAlphaComponent(0.3).cgColor
            focusBoxLayer.fillColor = UIColor.clear.cgColor
            focusBoxLayer.lineWidth = 1.0
            focusBoxLayer.shadowColor = UIColor.black.cgColor
            focusBoxLayer.shadowOpacity = 0.25
            focusBoxLayer.shadowOffset = .zero
            focusBoxLayer.shadowRadius = 2

            let initialSize: CGFloat = 86
            let finalSize: CGFloat = 72
            let initialRect = CGRect(x: point.x - initialSize/2, y: point.y - initialSize/2, width: initialSize, height: initialSize)
            let finalRect   = CGRect(x: point.x - finalSize/2,   y: point.y - finalSize/2,   width: finalSize,   height: finalSize)

            let initialPath = UIBezierPath(ovalIn: initialRect)
            let finalPath   = UIBezierPath(ovalIn: finalRect)

            focusBoxLayer.path = initialPath.cgPath
            focusBoxLayer.opacity = 0
            layer.addSublayer(focusBoxLayer)

            let animationGroup = CAAnimationGroup()
            animationGroup.duration = 0.25
            animationGroup.fillMode = .forwards
            animationGroup.isRemovedOnCompletion = false
            animationGroup.timingFunction = CAMediaTimingFunction(name: .easeOut)

            let pathAnimation = CABasicAnimation(keyPath: "path")
            pathAnimation.fromValue = initialPath.cgPath
            pathAnimation.toValue = finalPath.cgPath

            let opacityAnimation = CABasicAnimation(keyPath: "opacity")
            opacityAnimation.fromValue = 1.0
            opacityAnimation.toValue = 1.0

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

        // MARK: - Grid
        func showGrid() {
            gridLayer?.removeFromSuperlayer()
            let gridShapeLayer = CAShapeLayer()
            gridShapeLayer.strokeColor = UIColor(SnappieColor.primaryLight).cgColor
            gridShapeLayer.lineWidth = 1
            gridShapeLayer.fillColor = UIColor.clear.cgColor
            layer.addSublayer(gridShapeLayer)
            gridLayer = gridShapeLayer
            redrawGrid()
        }

        func hideGrid() {
            gridLayer?.removeFromSuperlayer()
            gridLayer = nil
        }

        func redrawGrid() {
            guard let gridLayer else { return }
            // 프리뷰 레이어의 실제 비디오 영역(크롭 반영)
            let videoRect = videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: CGRect(x: 0, y: 0, width: 1, height: 1))
            let path = UIBezierPath()

            // 세로 2줄
            let vSpacing = videoRect.width / 3
            for i in 1..<3 {
                let x = videoRect.minX + CGFloat(i) * vSpacing
                path.move(to: CGPoint(x: x, y: videoRect.minY))
                path.addLine(to: CGPoint(x: x, y: videoRect.maxY))
            }
            // 가로 2줄
            let hSpacing = videoRect.height / 3
            for i in 1..<3 {
                let y = videoRect.minY + CGFloat(i) * hSpacing
                path.move(to: CGPoint(x: videoRect.minX, y: y))
                path.addLine(to: CGPoint(x: videoRect.maxX, y: y))
            }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            gridLayer.path = path.cgPath
            CATransaction.commit()
        }
    }

    // MARK: - UIViewRepresentable
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black

        // 프리뷰 레이어 구성
        let layer = view.videoPreviewLayer
        layer.videoGravity = .resizeAspectFill
        layer.session = session

        // 실제 사용 중인 CameraManager에 프리뷰 레이어 바인딩
        cameraManager.bindPreviewLayer(layer)

        layer.connection?.videoRotationAngle = 90

        view.layer.cornerRadius = 24
        view.layer.masksToBounds = true

        view.handleFocus = tabToFocus
        view.handlePinchZoom = onPinchZoom
        view.setupGestures()
        return view
    }

    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        // 세션이 교체되면 갱신
        if uiView.videoPreviewLayer.session !== session {
            uiView.videoPreviewLayer.session = session
        }

        // 외부 상태 반영
        uiView.updateInitialZoomScale(currentZoomScale)
        uiView.isUsingFrontCamera = isUsingFrontCamera

        // 그리드 토글
        if showGrid {
            if uiView.gridLayer == nil { uiView.showGrid() } else { uiView.redrawGrid() }
        } else {
            uiView.hideGrid()
        }
    }
}
