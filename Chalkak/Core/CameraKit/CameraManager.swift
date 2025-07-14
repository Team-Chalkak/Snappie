//
//  CameraManager.swift
//  Chalkak
//
//  Created by 정종문 on 7/12/25.
//

import AVFoundation
import Foundation
import Photos
import SwiftUI

class CameraManager: NSObject, ObservableObject {
    var session = AVCaptureSession()
    var videoDeviceInput: AVCaptureDeviceInput!
    let movieOutput = AVCaptureMovieFileOutput()
    
    @Published var isRecording = false
    @Published var currentZoomScale: CGFloat = 1.0
    
    // 현재 사용 중인 카메라 타입 추적
    private var currentCameraType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera
    deinit {
        NotificationCenter.default.removeObserver(self)
        session.stopRunning()
    }
    
    /// 전면or후면 카메라 디바이스 가져오기
    private func getCamera(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }
    
    func setUpCamera() {
        if let device = getCamera(for: .back) {
            do {
                // 카메라연결
                videoDeviceInput = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(videoDeviceInput) {
                    session.addInput(videoDeviceInput)
                }
                
                // 동영상 추가
                if session.canAddOutput(movieOutput) {
                    session.addOutput(movieOutput)
                }

                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    self?.session.startRunning()
                }
                // CameraPreview에서 탭제스처에대해서 알림센터를 통해서 전달받음
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(focusAtPoint),
                    name: .init("FocusAtPoint"),
                    object: nil
                )
            } catch {
                print(error)
            }
        }
    }
    
    /// 켜져있는 플래쉬는 Torch로 표현
    func setTorchMode(_ isFlash: Bool) {
        guard let device = videoDeviceInput?.device else { return }
            
        do {
            try device.lockForConfiguration()
                
            if device.hasTorch && device.isTorchAvailable {
                device.torchMode = isFlash ? .on : .off
                // 플래쉬 밝기설정 / 0.0~1.0
                // 레벨설정도 가능
                if isFlash {
                    try device.setTorchModeOn(level: 1.0)
                }
            } else {
                print("이 기기는 플래시/토치를 지원하지 않습니다.")
            }
                
            device.unlockForConfiguration()
        } catch {
            print("플래시/토치 모드 설정 오류: \(error)")
        }
    }
    
    // 터치한 위치에대한 초점조정
    @objc func focusAtPoint(_ notification: Notification) {
        guard let point = notification.userInfo?["point"] as? CGPoint else { return }
        
        guard let device = videoDeviceInput?.device else { return }
        
        do {
            try device.lockForConfiguration()
            
            // 초점조절
            if device.isFocusModeSupported(.autoFocus) {
                device.focusMode = .autoFocus
                device.focusPointOfInterest = point
            }
            
            // 노출조절
            if device.isExposureModeSupported(.autoExpose) {
                device.exposureMode = .autoExpose
                device.exposurePointOfInterest = point
            }
            
            device.unlockForConfiguration()
            
        } catch {
            print("초점 에러\(error)")
        }
    }
    
    /// 카메라 전환
    private func switchCamera(to deviceType: AVCaptureDevice.DeviceType, targetZoom: CGFloat) {
        guard let newDevice = AVCaptureDevice.default(deviceType, for: .video, position: .back) else {
            return
        }
            
        session.beginConfiguration()
            
        if let existingInput = videoDeviceInput {
            session.removeInput(existingInput)
        }
            
        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: newDevice)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                currentCameraType = deviceType

                // 새 카메라에서 줌 설정
                adjustZoomOnCurrentCamera(targetZoom)
            }
        } catch {
            print("카메라 전환 에러 \(error)")
        }
            
        session.commitConfiguration()
    }
    
    func switchCamera(to position: AVCaptureDevice.Position) {
        session.beginConfiguration()
            
        if let existingInput = videoDeviceInput {
            session.removeInput(existingInput)
        }
            
        // 새로운 카메라 디바이스 가져오기
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
            do {
                videoDeviceInput = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(videoDeviceInput) {
                    session.addInput(videoDeviceInput)
                    // 카메라 타입 업데이트
                    currentCameraType = .builtInWideAngleCamera
                }
            } catch {
                print("카메라 전환 중 오류: \(error)")
            }
        }
            
        session.commitConfiguration()
    }
    
    func setZoomScale(_ scale: CGFloat) {
        let uiMinZoom: CGFloat = 0.5
        let uiMaxZoom: CGFloat = 6.0
        let clampedUIScale = min(max(scale, uiMinZoom), uiMaxZoom)
            
        // 줌의 정도에따라서 카메라 타입 변환
        let requiredCameraType: AVCaptureDevice.DeviceType
        if clampedUIScale < 1.0 {
            requiredCameraType = .builtInUltraWideCamera
        } else if clampedUIScale <= 2.0 {
            requiredCameraType = .builtInWideAngleCamera
        } else {
            requiredCameraType = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) != nil ? .builtInTelephotoCamera : .builtInWideAngleCamera
        }
            
        if requiredCameraType != currentCameraType {
            switchCamera(to: requiredCameraType, targetZoom: clampedUIScale)
        } else {
            adjustZoomOnCurrentCamera(clampedUIScale)
        }
    }
    
    // 현재 카메라에서 줌 조정
    private func adjustZoomOnCurrentCamera(_ uiScale: CGFloat) {
        guard let device = videoDeviceInput?.device else { return }
           
        do {
            try device.lockForConfiguration()
               
            let deviceMinZoom = device.minAvailableVideoZoomFactor
            let deviceMaxZoom = device.maxAvailableVideoZoomFactor
               
            // 카메라 타입별로 줌 조정
            let deviceZoom: CGFloat
            switch currentCameraType {
            case .builtInUltraWideCamera:
                let progress = (uiScale - 0.5) / (1.0 - 0.5)
                deviceZoom = 1.0 + min(1.0, deviceMaxZoom - 1.0) * progress
                   
            case .builtInWideAngleCamera:
                deviceZoom = uiScale
                   
            case .builtInTelephotoCamera:
                let progress = (uiScale - 2.0) / (6.0 - 2.0)
                deviceZoom = 1.0 + min(3.0, deviceMaxZoom - 1.0) * progress
                   
            default:
                deviceZoom = min(uiScale, deviceMaxZoom)
            }
               
            let finalZoom = min(max(deviceZoom, deviceMinZoom), deviceMaxZoom)
               
            device.videoZoomFactor = finalZoom
            currentZoomScale = uiScale
               
            device.unlockForConfiguration()
            
        } catch {
            print("줌 조정 에러 \(error)")
        }
    }
    
    func requestAndCheckPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] authStatus in
                if authStatus {
                    DispatchQueue.main.async {
                        self?.setUpCamera()
                    }
                }
            }
        case .restricted:
            break
        case .authorized:
            setUpCamera()
        default: // 거절
            print("Permession declined")
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videoName = "video_\(Date().timeIntervalSince1970).mp4"
        let videoURL = documentsPath.appendingPathComponent(videoName)
        
        movieOutput.startRecording(to: videoURL, recordingDelegate: self)
        isRecording = true
    }

    func stopRecording() {
        guard isRecording else { return }
        
        movieOutput.stopRecording()
        isRecording = false
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("녹화에러 \(error)")
            return
        }
        Task {
            await saveVideoToLibrary(videoURL: outputFileURL)
        }
    }

    @MainActor
    private func saveVideoToLibrary(videoURL: URL) async {
        let authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch authorizationStatus {
        case .notDetermined:
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            if status == .authorized || status == .limited {
                await performVideoSave(videoURL: videoURL)
            } else {
                print("라이브러리 권한 거부")
            }
        case .authorized, .limited:
            await performVideoSave(videoURL: videoURL)
        default:
            print("라이브러리 접근 권한 없음")
        }
    }
    
    private func performVideoSave(videoURL: URL) async {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }
        } catch {
            print("동영상 저장 에러\(error.localizedDescription)")
        }
    }
}
