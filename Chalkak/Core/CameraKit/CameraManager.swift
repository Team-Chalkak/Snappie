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
    @Published var showOnboarding = !UserDefaults.standard.bool(forKey: UserDefaultKey.hasCompletedOnboarding)
    // 앱 실행 시 카메라 화면에서 카메라, 마이크 권한 체크
    @Published private var videoAuthorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published private(set) var audioAuthorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var permissionState: PermissionState = .none
    @Published var showPermissionSheet: Bool = false
    @Published var isRecording = false
    @Published var currentZoomScale: CGFloat = 1.0
    @Published var torchMode: TorchMode = .off
    private var audioRecordPermission: AVAudioApplication.recordPermission = AVAudioApplication.recordPermission.undetermined

    var session = AVCaptureSession()
    var videoDeviceInput: AVCaptureDeviceInput!
    let movieOutput = AVCaptureMovieFileOutput()
    let videoOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(
        label: "com.camera.videoDataOutputQueue",
        qos: .userInitiated
    )

    private let boundingBoxManager = BoundingBoxManager()

    /// 비디오 저장 이벤트발생시 clipEditView로 URL전달
    /// 상태를 별도로 저장할 필요가 없어서 @Published 대신 PassthroughSubject 활용
    let savedVideoInfo = PassthroughSubject<URL, Never>()

    var onMultiBoundingBoxUpdate: (([CGRect]) -> Void)? {
        didSet {
            boundingBoxManager.onMultiBoundingBoxUpdate = onMultiBoundingBoxUpdate
        }
    }

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

    override init() {
        super.init()

        if !showOnboarding {
            checkPermissions()
            if permissionState == .both {
                Task {
                    await setUpCamera()
                }
            }
        }
    }

    deinit {
        session.stopRunning()
    }

    // MARK: permission

    @inline(__always)
    private func currentMicPermission() -> AVAudioApplication.recordPermission {
        return AVAudioApplication.shared.recordPermission
    }

    // MARK: permission

    @inline(__always)
    private func mapToAVAuthorization(_ record: AVAudioApplication.recordPermission) -> AVAuthorizationStatus {
        switch record {
        case .granted: return .authorized
        case .denied: return .denied
        case .undetermined: return .notDetermined
        @unknown default: return .denied
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: UserDefaultKey.hasCompletedOnboarding)
        showOnboarding = false

        checkPermissions()
    }

    // MARK: permission

    private func checkPermissions() {
        videoAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        audioRecordPermission = currentMicPermission()
        audioAuthorizationStatus = mapToAVAuthorization(audioRecordPermission)
        updatePermissionState()
    }

    // MARK: permission

    private func updatePermissionState() {
        let videoGranted = (videoAuthorizationStatus == .authorized)
        let audioGranted = (audioAuthorizationStatus == .authorized)

        switch (videoGranted, audioGranted) {
        case (true, true):
            permissionState = .both
            showPermissionSheet = false

        case (true, false):
            permissionState = .cameraOnly

            let shouldShow = !isRequestingPermissions && (audioAuthorizationStatus == .denied)
            showPermissionSheet = shouldShow

        case (false, true):
            permissionState = .audioOnly

            let videoDenied = (videoAuthorizationStatus == .denied || videoAuthorizationStatus == .restricted)
            let shouldShow = !isRequestingPermissions && videoDenied
            showPermissionSheet = shouldShow

        case (false, false):
            permissionState = .none

            let videoDenied = (videoAuthorizationStatus == .denied || videoAuthorizationStatus == .restricted)
            let audioDenied = (audioAuthorizationStatus == .denied)

            let hasActualDenial = videoDenied || audioDenied
            let shouldShow = !isRequestingPermissions && hasActualDenial
            showPermissionSheet = shouldShow
        }
    }

    // MARK: permission

    @MainActor
    func requestAndCheckPermissions() {
        guard !isRequestingPermissions else { return }
        isRequestingPermissions = true

        // 최신 상태 캐싱
        checkPermissions()

        requestCameraIfNeeded { [weak self] in
            self?.requestMicIfNeeded { [weak self] in
                self?.finishPermissionRequest() // 두 알럿 콜백 종료 시점 단 한 번
            }
        }
    }

    // MARK: permission

    /// 앱 첫 실행에서만 호출

    @MainActor
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

    // MARK: permission

    private func requestCameraIfNeeded(completion: @escaping () -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] _ in
                Task { @MainActor in
                    self?.videoAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
                    completion()
                }
            }
        default:
            videoAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            completion()
        }
    }

    // MARK: permission

    @MainActor
    private func requestMicIfNeeded(completion: @escaping () -> Void) {
        let currentPermission = currentMicPermission()

        if currentPermission == AVAudioApplication.recordPermission.undetermined {
            AVAudioApplication.requestRecordPermission { [weak self] _ in
                Task { @MainActor in
                    self?.audioRecordPermission = self?.currentMicPermission() ?? AVAudioApplication.recordPermission.undetermined
                    self?.audioAuthorizationStatus = self?.mapToAVAuthorization(self?.audioRecordPermission ?? AVAudioApplication.recordPermission.undetermined) ?? .notDetermined
                    completion()
                }
            }
        } else {
            audioRecordPermission = currentPermission
            audioAuthorizationStatus = mapToAVAuthorization(currentPermission)
            completion()
        }
    }

    // MARK: permission

    private func finishPermissionRequest() {
        DispatchQueue.main.async { [weak self] in
            self?.isRequestingPermissions = false

            // 최신 상태 갱신
            self?.checkPermissions()

            // 권한 모두 허용 시 카메라 설정
            if self?.permissionState == .both {
                Task { @MainActor in
                    await self?.setUpCamera()
                }
            }
        }
    }

    // MARK: permission

    func reevaluateAndPresentIfNeeded() {
        checkPermissions()

        if !isRequestingPermissions {
            showPermissionSheet = (permissionState != .both)
        }
    }

    // MARK: permission

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    /// 카메라 세팅
    /// 비디오,오디오 연결
    @MainActor
    func setUpCamera() async {
        let position = initialCameraPosition

        let device: AVCaptureDevice?
        if position == .back {
            device = findBestBackCamera()
        } else {
            device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        }

        guard let device = device else {
            print("카메라 디바이스를 찾을 수 없습니다")
            return
        }

        do {
            // 세션 설정
            session.beginConfiguration()
            defer { session.commitConfiguration() }

            // 비디오 입력 설정
            videoDeviceInput = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
            }

            // 오디오 입력 추가
            if let audioDevice = AVCaptureDevice.default(for: .audio) {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if session.canAddInput(audioInput) {
                    session.addInput(audioInput)
                }
            }

            // 카메라 출력 설정
            if session.canAddOutput(movieOutput) {
                session.addOutput(movieOutput)
            }

            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
                videoOutput.setSampleBufferDelegate(boundingBoxManager, queue: videoDataOutputQueue)
                videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            }

            // 세션 설정 이후 프레임,초점
            try configureCameraSettings(for: device)

            // 시작카메라 줌 배율 설정
            setZoomScale(backCameraZoomScale)

        } catch {
            print("카메라 설정 오류: \(error)")
        }
    }

    /// 모든 카메라 설정을 한 번의 lockForConfiguration으로 처리
    private func configureCameraSettings(for device: AVCaptureDevice) throws {
        // 최적 포맷찾기 lock이전에 미리 계산
        let bestFormat = findBestFormat(for: device)

        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }

        // 포맷 설정
        if let format = bestFormat {
            device.activeFormat = format
        }

        // fps설정
        let supportedRanges = device.activeFormat.videoSupportedFrameRateRanges
        let supports60fps = supportedRanges.contains { $0.maxFrameRate >= 60 }
        let fps = supports60fps ? 60 : 30
        let frameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))
        device.activeVideoMinFrameDuration = frameDuration
        device.activeVideoMaxFrameDuration = frameDuration

        // 초점 설정
        if device.isSmoothAutoFocusSupported {
            device.isSmoothAutoFocusEnabled = true
        }
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }
        /// 자동 조정 모드 설정
        ///  - .none = 제한 없음 (가까운 곳~먼 곳 다 초점 가능)
        ///  - .near = 가까운 곳만 초점
        ///  - .far = 먼 곳만 초점
        if device.isAutoFocusRangeRestrictionSupported {
            device.autoFocusRangeRestriction = .none
        }

        // 노출 설정
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }

        // 줌 설정
        let minZoom = device.minAvailableVideoZoomFactor
        let maxZoom = device.maxAvailableVideoZoomFactor
        let zoomFactorToSet = backCameraZoomScale * 2.0
        let clampedZoomFactor = max(minZoom, min(zoomFactorToSet, maxZoom))
        device.videoZoomFactor = clampedZoomFactor

        // 카메라 줌 UI반영
        DispatchQueue.main.async { [weak self] in
            self?.currentZoomScale = self?.backCameraZoomScale ?? 1.0
        }
    }

    /// 60fps 지원 최적 포맷 찾기 (lockForConfiguration전에 미리 계산 - 충돌방지)
    private func findBestFormat(for device: AVCaptureDevice) -> AVCaptureDevice.Format? {
        var bestFormat: AVCaptureDevice.Format?
        var maxResolution: Int32 = 0

        // 1080p제한 (1920x1080 = 2073600)
        let maxAllowedResolution: Int32 = 2_073_600
        // 높은 해상도기준 정렬
        let sortedFormats = device.formats.sorted { format1, format2 in
            let dim1 = CMVideoFormatDescriptionGetDimensions(format1.formatDescription)
            let dim2 = CMVideoFormatDescriptionGetDimensions(format2.formatDescription)
            let res1 = dim1.width * dim1.height
            let res2 = dim2.width * dim2.height
            return res1 > res2
        }

        // 최적 포맷(1080p,60fps)에 근접할 수 있게 탐색
        for format in sortedFormats {
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let currentResolution = dimensions.width * dimensions.height

            // 1080p 이하인지 확인
            guard currentResolution <= maxAllowedResolution else { continue }

            if currentResolution <= maxResolution { continue }

            let supports60fps = format.videoSupportedFrameRateRanges.contains { range in
                range.maxFrameRate >= 60
            }

            if supports60fps {
                bestFormat = format
                maxResolution = currentResolution
                // 최고 해상도 -> 조기 종료
                break
            }
        }

        return bestFormat
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

    /// 전-후면 카메라 전환
    func switchCamera(to newPosition: AVCaptureDevice.Position) {
        guard let currentDevice = videoDeviceInput?.device else {
            return
        }

        // 후면카메라일때 줌 스케일 저장
        if currentDevice.position == .back {
            backCameraZoomScale = currentZoomScale
        }

        // 전환을 위한 카메라 탐색
        let newDevice: AVCaptureDevice?
        if newPosition == .back {
            newDevice = findBestBackCamera()
        } else {
            newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        }

        guard let device = newDevice else {
            return
        }
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }

        // 모든 비디오input 제거
        let allInputs = session.inputs
        for input in allInputs {
            if let deviceInput = input as? AVCaptureDeviceInput,
               deviceInput.device.hasMediaType(.video)
            {
                session.removeInput(deviceInput)
            }
        }

        do {
            // 새로운 비디오 입력 생성
            let newInput = try AVCaptureDeviceInput(device: device)

            guard session.canAddInput(newInput) else {
                return
            }
            // 카메라 설정 적용
            try configureCameraSettings(for: device)

            session.addInput(newInput)
            videoDeviceInput = newInput

            // 카메라 위치 저장
            initialCameraPosition = newPosition

            if let connection = movieOutput.connection(with: .video) {
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = newPosition == .front
                }
            }

        } catch {
            // 실패시 기존 카메라 복구
            if let fallbackInput = try? AVCaptureDeviceInput(device: device),
               session.canAddInput(fallbackInput)
            {
                session.addInput(fallbackInput)
                videoDeviceInput = fallbackInput
            } else {
                print("카메라 복구 실패")
            }
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
        // 권한 체크 후 카메라세션 시작
        checkPermissions()
        if permissionState == .both, session.inputs.isEmpty {
            Task {
                await setUpCamera()
                startSessionInternal()
            }
        } else {
            startSessionInternal()
        }
    }

    private func startSessionInternal() {
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
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("녹화에러 \(error)")
            return
        }
        videoSaved(url: outputFileURL)
    }
}
