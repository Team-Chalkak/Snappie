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

    deinit {
        NotificationCenter.default.removeObserver(self)
        session.stopRunning()
    }
    
    func setUpCamera() {
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                for: .video, position: .back)
        {
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
    
    func switchCamera(to position: AVCaptureDevice.Position) {
        session.beginConfiguration()
        
        // 기존에 연결된 input 제거
        if let existingInput = videoDeviceInput {
            session.removeInput(existingInput)
        }
        
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
            do {
                videoDeviceInput = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(videoDeviceInput) {
                    session.addInput(videoDeviceInput)
                }
            } catch {
                print("카메라 전환에러\(error)")
            }
        }
        
        session.commitConfiguration()
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
            print("동엿ㅇ상 저장 에러 \(error.localizedDescription)")
        }
    }
}
