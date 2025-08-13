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
    @Published private(set) var audioAuthorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var permissionState: PermissionState = .none
    @Published var showPermissionSheet: Bool = false
    
    private var audioRecordPermission: AVAudioSession.RecordPermission = .undetermined
    
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

    
    private var isRequestingPermissions = false
    private var didBecomeActiveObserver: NSObjectProtocol?
    
    override init() {
        super.init()
        checkPermissions()
        
        didBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reevaluateAndPresentIfNeeded()
        }
    }
    
    deinit {
        session.stopRunning()
        if let token = didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(token)
        }
    }

    
    @inline(__always)
    private func currentMicPermission() -> AVAudioSession.RecordPermission {
        return AVAudioSession.sharedInstance().recordPermission
    }

    @inline(__always)
    private func mapToAVAuthorization(_ record: AVAudioSession.RecordPermission) -> AVAuthorizationStatus {
        switch record {
        case .granted:      return .authorized
        case .denied:       return .denied
        case .undetermined: return .notDetermined
        @unknown default:   return .denied
        }
    }

    
    
//    private func checkPermissionsWithoutSheet() {
//        videoAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
//        audioRecordPermission = currentMicPermission()
//        audioAuthorizationStatus = mapToAVAuthorization(audioRecordPermission)
//        updatePermissionStateOnly() // 시트 표시 없이 상태만 업데이트
//    }
    
    
    func checkPermissions() {
        videoAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        audioRecordPermission = currentMicPermission()
        audioAuthorizationStatus = mapToAVAuthorization(audioRecordPermission)
        updatePermissionState()
    }
    
//    private func updatePermissionStateOnly() {
//        let videoGranted = (videoAuthorizationStatus == .authorized)
//        let audioGranted = (audioAuthorizationStatus == .authorized)
//
//        switch (videoGranted, audioGranted) {
//        case (true, true):   permissionState = .both
//        case (true, false):  permissionState = .cameraOnly
//        case (false, true):  permissionState = .audioOnly
//        case (false, false): permissionState = .none
//        }
//  
//    }
    
    private func updatePermissionState() {
        let videoGranted = (videoAuthorizationStatus == .authorized)
        let audioGranted = (audioAuthorizationStatus == .authorized)

        switch (videoGranted, audioGranted) {
        case (true, true):
            permissionState = .both
            showPermissionSheet = false

        case (true, false):
            permissionState = .cameraOnly
            // 🔥 .denied 상태일 때만 시트 표시 (.notDetermined는 제외)
            let shouldShow = !isRequestingPermissions && (audioAuthorizationStatus == .denied)
            showPermissionSheet = shouldShow

        case (false, true):
            permissionState = .audioOnly
            // 🔥 .denied 또는 .restricted 상태일 때만 시트 표시
            let videoDenied = (videoAuthorizationStatus == .denied || videoAuthorizationStatus == .restricted)
            let shouldShow = !isRequestingPermissions && videoDenied
            showPermissionSheet = shouldShow

        case (false, false):
            permissionState = .none
            // 🔥 실제로 거부된 권한이 있을 때만 시트 표시
            let videoDenied = (videoAuthorizationStatus == .denied || videoAuthorizationStatus == .restricted)
            let audioDenied = (audioAuthorizationStatus == .denied)
            
            // 🔥 핵심: 둘 다 .notDetermined이면 시트 표시 안함
            let hasActualDenial = videoDenied || audioDenied
            let shouldShow = !isRequestingPermissions && hasActualDenial
            showPermissionSheet = shouldShow
        }
    }
    
//    
//    func requestAndCheckPermissions() {
//        guard !isRequestingPermissions else { return }
//        isRequestingPermissions = true
//
//        // 최신 상태 캐싱
//        checkPermissions()
//
//        requestCameraIfNeeded { [weak self] in
//            self?.requestMicIfNeeded { [weak self] in
//                self?.finishPermissionRequest()  // 두 알럿 콜백 종료 시점 단 한 번
//            }
//        }
//    }
//    
    /// 앱 첫 실행에서만 호출
    func requestPermissionsIfNeededAtFirstLaunch() {
        guard !isRequestingPermissions else { return }
        isRequestingPermissions = true
        showPermissionSheet = false
        
        checkPermissions()
        
        requestCameraIfNeeded { [weak self] in
            self?.requestMicIfNeeded { [weak self] in
                self?.finishPermissionRequest()
            }
        }
    }

    private func requestCameraIfNeeded(completion: @escaping () -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.videoAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
                    completion()
                }
            }
        default:
            videoAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            completion()
        }
    }

    private func requestMicIfNeeded(completion: @escaping () -> Void) {
        let currentPermission = currentMicPermission()
        
        if currentPermission == .undetermined {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] _ in
                DispatchQueue.main.async {
                    self?.audioRecordPermission = self?.currentMicPermission() ?? .undetermined
                    self?.audioAuthorizationStatus = self?.mapToAVAuthorization(self?.audioRecordPermission ?? .undetermined) ?? .notDetermined
                    completion()
                }
            }
        } else {
            audioRecordPermission = currentPermission
            audioAuthorizationStatus = mapToAVAuthorization(currentPermission)
            completion()
        }
    }

    private func finishPermissionRequest() {
        // 🔥 알럿이 완전히 사라질 때까지 대기 (1초로 증가)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            // 요청 완료 플래그
            self?.isRequestingPermissions = false
            
            // 최신 상태 갱신
            self?.checkPermissions()
            
            // 권한 모두 허용 시 카메라 설정
            if self?.permissionState == .both {
                self?.setUpCamera()
            }
        }
    }

    func reevaluateAndPresentIfNeeded() {
        checkPermissions()
        // 🔥 권한 요청 중일 때는 시트 상태 변경하지 않음
        if !isRequestingPermissions {
            showPermissionSheet = (permissionState != .both)
        }
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
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
