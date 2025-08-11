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
    // 앱 실행 시 카메라 화면에서 카메라, 마이크 권한 체크
    @Published var videoAuthorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var audioAuthorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var showPermissionSheet = false
    @Published var permissionState: PermissionState = .none
    
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
    
    private var isRequestingPermissions = false
        
    override init() {
        super.init()
        checkPermissions()
    }
        
    
    func checkPermissions() {
        videoAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        audioAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        updatePermissionState()
    }
    
    private func updatePermissionState() {
        let videoGranted = videoAuthorizationStatus == .authorized
        let audioGranted = audioAuthorizationStatus == .authorized
        let videoNotDetermined = videoAuthorizationStatus == .notDetermined  // ✅ 추가
        let audioNotDetermined = audioAuthorizationStatus == .notDetermined   // ✅ 추가
        
        switch (videoGranted, audioGranted) {
        case (true, true):
            permissionState = .both
            showPermissionSheet = false

            
        case (true, false):
            permissionState = .cameraOnly
            // 마이크 권한이 명시적으로 거부된 경우에만 시트 표시
            let shouldShow = !isRequestingPermissions &&
            (audioAuthorizationStatus == .denied || audioAuthorizationStatus == .restricted)
            showPermissionSheet = shouldShow
   
            
        case (false, true):
            permissionState = .audioOnly
            // 카메라 권한이 명시적으로 거부된 경우에만 시트 표시
            let shouldShow = !isRequestingPermissions &&
            (videoAuthorizationStatus == .denied || videoAuthorizationStatus == .restricted)
            showPermissionSheet = shouldShow

            
        case (false, false):
            permissionState = .none
            // 둘 중 하나라도 명시적으로 거부된 경우에 시트 표시
            let videoDenied = videoAuthorizationStatus == .denied || videoAuthorizationStatus == .restricted
            let audioDenied = audioAuthorizationStatus == .denied || audioAuthorizationStatus == .restricted
            let shouldShow = !isRequestingPermissions && (videoDenied || audioDenied)
            showPermissionSheet = shouldShow

        }
    }

    
    
    func requestAndCheckPermissions() {
        // 이미 요청 중이면 중복 실행 방지
          guard !isRequestingPermissions else { return }
          
          isRequestingPermissions = true
        
        // 비디오 권한 확인
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:

            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
 
                DispatchQueue.main.async {
                    self?.videoAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
                    // 오디오 권한도 확인
                    self?.checkAudioPermission()
                }
            }
        case .restricted, .denied:
 
            DispatchQueue.main.async {
                self.videoAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
                // 비디오가 거부되어도 오디오 권한 확인
                self.checkAudioPermission()
            }
        case .authorized:

            checkAudioPermission()
        @unknown default:
            checkAudioPermission()
        }
    }
    
    private func checkAudioPermission() {
        // 오디오 권한 확인
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined:

            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
 
                DispatchQueue.main.async {
                    self?.audioAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .audio)
                    self?.finishPermissionRequest()
                }
            }
        case .restricted, .denied:
            DispatchQueue.main.async {
                self.audioAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .audio)
                self.finishPermissionRequest()
            }
        case .authorized:
            DispatchQueue.main.async {
                self.audioAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .audio)
                self.finishPermissionRequest()
            }
        @unknown default:
            DispatchQueue.main.async {
                self.audioAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .audio)
                self.finishPermissionRequest()
            }
        }
    }
    
    private func finishPermissionRequest() {
        
        // 카메라 설정
        if permissionState == .both {
            setUpCamera()
        }
        
        isRequestingPermissions = false
        
        // 권한 상태 업데이트
        updatePermissionState()
        
        // 시트 표시 재확인 (약간의 지연 후)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.forceCheckPermissionSheet()
        }
    }
    
    private func forceCheckPermissionSheet() {
        let videoGranted = videoAuthorizationStatus == .authorized
        let audioGranted = audioAuthorizationStatus == .authorized
        let hasPermissionIssue = !videoGranted || !audioGranted
        
        if hasPermissionIssue && !isRequestingPermissions {
            showPermissionSheet = true
        }
    }
    
    func refreshPermissions() {
        checkPermissions()
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

            // 부드러운 초점 전환 설정
            configureSmoothFocus(for: device)

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

            // 세션 시작은 startSession() 메서드를 통해 명시적으로 호출하도록 변경
            // 최초 카메라 설정 시 1.0 줌배율적용
            DispatchQueue.main.async {
                self.setZoomScale(self.backCameraZoomScale)
            }
        } catch {
            print("카메라 설정 오류: \(error)")
        }
    }
    
    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func checkAndShowPermissionSheet() {
        // 약간의 지연을 두고 UI 업데이트 확인
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            let videoGranted = self?.videoAuthorizationStatus == .authorized
            let audioGranted = self?.audioAuthorizationStatus == .authorized
            let hasPermissionIssue = !videoGranted || !audioGranted
            
            if hasPermissionIssue && !(self?.showPermissionSheet ?? false) {

                self?.showPermissionSheet = true
            }
        }
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
                        print(format)
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

    /// 부드러운 초점 전환 촬영 세팅
    private func configureSmoothFocus(for device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()

            // smooth 초점전환방식 활성화
            if device.isSmoothAutoFocusSupported {
                device.isSmoothAutoFocusEnabled = true
            }

            // 자동 초점
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }

            // 자동 노출
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }

            /// 자동 조정 모드 설정
            ///  - .none = 제한 없음 (가까운 곳~먼 곳 다 초점 가능)
            ///  - .near = 가까운 곳만 초점
            ///  - .far = 먼 곳만 초점
            if device.isAutoFocusRangeRestrictionSupported {
                device.autoFocusRangeRestriction = .none
            }

            device.unlockForConfiguration()
        } catch {
            print("부드러운 초점 설정 오류: \(error)")
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
//    func focusAtPoint(_ point: CGPoint) {
//        guard let device = videoDeviceInput?.device else { return }
//
//        do {
//            try device.lockForConfiguration()
//
//            // 부드러운 초점 전환을 위한 설정
//            if device.isSmoothAutoFocusSupported {
//                device.isSmoothAutoFocusEnabled = true
//            }
//
//            // 초점,노출 지점접근
//            device.focusPointOfInterest = point
//            device.exposurePointOfInterest = point
//
//            // 초점
//            if device.isFocusModeSupported(.continuousAutoFocus) {
//                device.focusMode = .continuousAutoFocus
//            } else if device.isFocusModeSupported(.autoFocus) {
//                device.focusMode = .autoFocus
//            }
//
//            // 노출
//            if device.isExposureModeSupported(.continuousAutoExposure) {
//                device.exposureMode = .continuousAutoExposure
//            } else if device.isExposureModeSupported(.autoExpose) {
//                device.exposureMode = .autoExpose
//            }
//
//            device.unlockForConfiguration()
//        } catch {
//            print("디바이스 설정 변경오류\(error)")
//        }
//    }
    func focusAtPoint(_ point: CGPoint) {
        guard let device = videoDeviceInput?.device else { return }

        do {
            try device.lockForConfiguration()

            // 포인트 설정
            device.focusPointOfInterest = point
            device.exposurePointOfInterest = point

            // 최소한 초점 모드는 보장 (중복이어도 안전함)
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }

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
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                videoDeviceInput = newInput
                configureFrameRate(for: newDevice)
                configureSmoothFocus(for: newDevice)
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



    /// 카메라 세션 시작
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    /// 카메라 세션 중지
    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
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
