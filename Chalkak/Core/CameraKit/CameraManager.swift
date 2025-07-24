//
//  CameraManager.swift
//  Chalkak
//
//  Created by 정종문 on 7/12/25.
//

import AVFoundation
import Combine
import Foundation
import Photos
import SwiftUI

class CameraManager: NSObject, ObservableObject {
    var session = AVCaptureSession()
    var videoDeviceInput: AVCaptureDeviceInput!
    let movieOutput = AVCaptureMovieFileOutput()
    let videoOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(
        label: "com.camera.videoDataOutputQueue",
        qos: .userInitiated
    )

    private let boundingBoxManager = BoundingBoxManager()

    @Published var torchMode: TorchMode = .off

    /// 비디오 저장 이벤트발생시 clipEditView로 URL전달
    /// 상태를 별도로 저장할 필요가 없어서 @Published 대신 PassthroughSubject 활용
    let savedVideoInfo = PassthroughSubject<URL, Never>()

    var onMultiBoundingBoxUpdate: (([CGRect]) -> Void)? {
        didSet {
            boundingBoxManager.onMultiBoundingBoxUpdate = onMultiBoundingBoxUpdate
        }
    }

    @Published var isRecording = false
    @Published var currentZoomScale: CGFloat = 1.0

    // 카메라 줌스케일
    private var backCameraZoomScale: CGFloat = 1.0
    private var initialCameraPosition: AVCaptureDevice.Position {
        get {
            if let savedValue = UserDefaults.standard.string(forKey: UserDefaultKey.cameraPosition),
               savedValue == "front"
            {
                return .front
            } else {
                return .back
            }
        }
        set {
            let value = newValue == .front ? "front" : "back"
            UserDefaults.standard.set(value, forKey: UserDefaultKey.cameraPosition)
        }
    }

    deinit {
        session.stopRunning()
    }

    override init() {
        super.init()
    }

    /// 지원하는 최대 1080p , 60fps포맷을 찾아서 설정
    private func configureFrameRate(for device: AVCaptureDevice) {
        var targetFormat: AVCaptureDevice.Format?
        var maxResolution: Int32 = 0

        // 카메라 기기가 지원하는 모든 포맷들을 하나씩 검사
        for format in device.formats {
            /// 현재 촬영하고자하는 해상도 정보 추출
            /// struct CMVideoDimensions { var width: Int32 / var height: Int32 }
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let currentResolution = dimensions.width * dimensions.height

            // 4K까지는 의미X 1080p(1920x1080의값2,073,600)이하로 제한
            if currentResolution <= 2073600 {
                // 이 포맷이 지원하는 프레임레이트 범위들을 확인
                for range in format.videoSupportedFrameRateRanges {
                    // 지금까지 찾은 것보다 더 높은 해상도인지 확인
                    if range.maxFrameRate >= 60, currentResolution > maxResolution {
                        targetFormat = format
                        maxResolution = currentResolution
                        break // 60fps 찾으면 break
                    }
                }
            }
        }

        // 조건에 맞는 포맷을 찾지 못한 경우 에러 처리
        guard let format = targetFormat else {
            print("현재 해상도에서 60fps를 지원하지 않습니다.")
            return
        }

        // 찾은 최적 포맷을 실제 카메라에 적용
        do {
            try device.lockForConfiguration()
            device.activeFormat = format // 선택된 포맷 적용

            // 프레임 60fps로 고정 설정
            let frameDuration = CMTime(value: 1, timescale: 60)
            // 최대 - 최소 프레임 60fps
            device.activeVideoMinFrameDuration = frameDuration
            device.activeVideoMaxFrameDuration = frameDuration
            device.unlockForConfiguration()

        } catch {
            print("프레임 설정 오류 \(error)")
        }
    }

    /// 후면 카메라 중 가장 좋은 성능의 카메라(가상 카메라 우선)를 찾아서 반환
    private func findBestBackCamera() -> AVCaptureDevice? {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInTripleCamera,
            .builtInDualWideCamera,
            .builtInDualCamera,
            .builtInWideAngleCamera
        ]
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .back
        )
        return discoverySession.devices.first
    }

    /// 카메라 세팅
    /// 비디오,오디오 연결
    func setUpCamera() {
        let position = initialCameraPosition
        let device = (position == .back) ? findBestBackCamera() : AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        )

        guard let device = device else { return }

        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
            }

            configureFrameRate(for: device)

            // 오디오 입력 추가
            if let audioDevice = AVCaptureDevice.default(for: .audio) {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if session.canAddInput(audioInput) {
                    session.addInput(audioInput)
                }
            }

            // 동영상 출력 추가
            if session.canAddOutput(movieOutput) {
                session.addOutput(movieOutput)
            }

            // 비디오 데이터 출력 추가 및 델리게이트 설정
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
                videoOutput.setSampleBufferDelegate(boundingBoxManager, queue: videoDataOutputQueue)
                videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            }

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
                DispatchQueue.main.async {
                    // 최초 카메라 설정 시 1.0 줌배율적용
                    self?.setZoomScale(self?.backCameraZoomScale ?? 1.0)
                }
            }
        } catch {
            print("카메라 설정 오류: \(error)")
        }
    }

    /// 토치 모드 설정
    func setTorchMode(_ mode: TorchMode) {
        torchMode = mode
        guard let device = videoDeviceInput?.device else { return }

        do {
            try device.lockForConfiguration()

            if device.hasTorch, device.isTorchAvailable {
                switch mode {
                case .off:
                    device.torchMode = .off
                case .on:
                    device.torchMode = .on
                case .auto:
                    device.torchMode = .auto
                }
            } else {
                print("이 기기는 플래시/토치를 지원하지 않습니다.")
            }

            device.unlockForConfiguration()
        } catch {
            print("플래시/토치 모드 설정 오류: \(error)")
        }
    }

    /// 터치한 위치값에 대한 초점을 조정하는 메소드
    func focusAtPoint(_ point: CGPoint) {
        guard let device = videoDeviceInput?.device else { return }

        do {
            try device.lockForConfiguration()

            // 초점,노출 지점접근
            device.focusPointOfInterest = point
            device.exposurePointOfInterest = point

            device.focusMode = .autoFocus
            device.exposureMode = .autoExpose

            device.unlockForConfiguration()
        } catch {
            print("디바이스 설정 변경오류\(error)")
        }
    }

    /// 비디오 저장 알림메소드
    func videoSaved(url: URL) {
        savedVideoInfo.send(url)
    }

    /// 전면/후면 카메라 전환
    func switchCamera(to newPosition: AVCaptureDevice.Position) {
        if let currentDevice = videoDeviceInput?.device {
            if currentDevice.position == .back {
                backCameraZoomScale = currentZoomScale
            }
        }

        session.beginConfiguration()
        session.removeInput(videoDeviceInput)

        let device = (newPosition == .back) ? findBestBackCamera() : AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)

        guard let newDevice = device else {
            session.commitConfiguration()
            return
        }
        if let connection = movieOutput.connection(with: .video) {
            // 전면카메라 좌우반전 제거
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = newPosition == .front
            }
        }

        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                videoDeviceInput = newInput
                configureFrameRate(for: newDevice)
                initialCameraPosition = newPosition
            }

        } catch {
            print("카메라 전환 중 오류: \(error)")
        }

        session.commitConfiguration()

        // 전환된 카메라의 저장된 줌 스케일 복원
        if newPosition == .back {
            let savedZoomScale = backCameraZoomScale
            setZoomScale(savedZoomScale)
        }
    }

    /// 줌 배율 설정 (가상 카메라를 사용하여 끊김 없는 줌)
    func setZoomScale(_ scale: CGFloat) {
        guard let device = videoDeviceInput?.device else { return }

        do {
            try device.lockForConfiguration()

            let minZoom = device.minAvailableVideoZoomFactor
            let maxZoom = device.maxAvailableVideoZoomFactor

            let zoomFactorToSet = scale * 2.0

            // 디바이스 지원 줌 범위로 값 제한
            let clampedZoomFactor = max(minZoom, min(zoomFactorToSet, maxZoom))

            device.videoZoomFactor = clampedZoomFactor
            currentZoomScale = scale

            // 현재 카메라 포지션에 따라 줌 스케일 저장
            if device.position == .back {
                backCameraZoomScale = scale
            }

            device.unlockForConfiguration()
        } catch {
            print("줌 조정 에러 \(error)")
        }
    }

    func requestAndCheckPermissions() {
        // 비디오 권한 확인
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.checkAudioPermission()
                }
            }
        case .restricted, .denied:
            print("비디오 권한이 거부되었습니다.")
        case .authorized:
            checkAudioPermission()
        @unknown default:
            break
        }
    }

    private func checkAudioPermission() {
        // 오디오 권한 확인
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setUpCamera()
                    }
                }
            }
        case .restricted, .denied:
            print("오디오 권한이 거부되었습니다.")
            DispatchQueue.main.async {
                self.setUpCamera() // 오디오 권한 없이 계속 진행
            }
        case .authorized:
            DispatchQueue.main.async {
                self.setUpCamera()
            }
        @unknown default:
            break
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
    /// 녹화가 끝나면 촬영한 파일 URL을 NotificationCenter를 통해 알림
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("녹화에러 \(error)")
            return
        }
        videoSaved(url: outputFileURL)
    }
}
