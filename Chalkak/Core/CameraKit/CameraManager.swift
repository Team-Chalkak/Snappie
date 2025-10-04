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
    @Published private(set) var isPreviewMirrored: Bool = false

    var onPreviewMirroringChanged: ((Bool) -> Void)?
    private weak var previewLayer: AVCaptureVideoPreviewLayer?

    // ✅ 정책(원하면 설정 화면에서 바꿀 수 있게)
    var recordingMirrorPolicy: RecordingMirrorPolicy = .followPreview
    // 현재 파일이 미러로 저장되고 있는지(Clip에 넘겨 기록용)
    @Published private(set) var isRecordingMirrored: Bool = false
    
    private var isRequestingPermissions = false
    private var didBecomeActiveObserver: NSObjectProtocol?

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

    func checkPermissions() {
        videoAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        audioRecordPermission = currentMicPermission()
        audioAuthorizationStatus = mapToAVAuthorization(audioRecordPermission)
        updatePermissionState()
    }

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

    func reevaluateAndPresentIfNeeded() {
        checkPermissions()

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
            
            // 프리뷰 레이어가 이미 바인딩되어 있다면 자동조정 켜고 현재 상태를 반영
            if let conn = previewLayer?.connection {
                conn.automaticallyAdjustsVideoMirroring = true
                propagatePreviewMirroring(from: conn)
            }
            
            updateRecordingMirroring()

        } catch {
            print("카메라 설정 오류: \(error)")
        }
    }

    /// 모든 카메라 설정을 한 번의 lockForConfiguration으로 처리
    private func configureCameraSettings(for device: AVCaptureDevice) throws {
        // 최적 포맷찾기 lock이전에 미리 계산)
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

            // ✅ 프리뷰는 자동조정 켜고, 현재 값 브로드캐스트
            if let conn = previewLayer?.connection {
                conn.automaticallyAdjustsVideoMirroring = true
                propagatePreviewMirroring(from: conn)
            }

            updateRecordingMirroring()

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
                // 세션이 돌기 시작하면 프리뷰 연결이 유효해지는 시점이므로 약간의 지연 후 갱신
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.refreshPreviewMirroring()
                    self.updateRecordingMirroring()
                }
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

extension CameraManager {
    /// 카메라 프리뷰 레이어를 연결하고, 미러링 자동조정을 활성화한다.
    func bindPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        previewLayer = layer
        layer.videoGravity = .resizeAspectFill

        // ✅ 시스템이 전/후면 전환/방향 등에 따라 적절히 판단하도록
        if let conn = layer.connection {
            conn.automaticallyAdjustsVideoMirroring = true
            // 초기 상태를 브로드캐스트
            propagatePreviewMirroring(from: conn)
            updateRecordingMirroring()
        }
    }
}

private extension CameraManager {
    func propagatePreviewMirroring(from connection: AVCaptureConnection?) {
        guard let connection = connection else { return }
        let mirrored = connection.isVideoMirrored

        if self.isPreviewMirrored != mirrored {
            DispatchQueue.main.async {
                self.isPreviewMirrored = mirrored
                self.onPreviewMirroringChanged?(mirrored)
                self.updateRecordingMirroring()
            }
        }
    }

    /// 프리뷰 레이어 연결에서 현재 미러링 상태를 읽어 반영
    func refreshPreviewMirroring() {
        propagatePreviewMirroring(from: previewLayer?.connection)
    }
    
    private func updateRecordingMirroring() {
        // movieOutput
        if let conn = movieOutput.connection(with: .video), conn.isVideoMirroringSupported {
            switch recordingMirrorPolicy {
            case .followPreview:
                conn.automaticallyAdjustsVideoMirroring = false
                conn.isVideoMirrored = isPreviewMirrored
                isRecordingMirrored = isPreviewMirrored
            case .alwaysMirrored:
                conn.automaticallyAdjustsVideoMirroring = false
                conn.isVideoMirrored = true
                isRecordingMirrored = true
            case .neverMirrored:
                conn.automaticallyAdjustsVideoMirroring = false
                conn.isVideoMirrored = false
                isRecordingMirrored = false
            }
        }

        // (선택) videoOutput도 파일 좌표계와 맞추고 싶으면 동일 처리
        if let conn = videoOutput.connection(with: .video), conn.isVideoMirroringSupported {
            switch recordingMirrorPolicy {
            case .followPreview: conn.isVideoMirrored = isPreviewMirrored
            case .alwaysMirrored: conn.isVideoMirrored = true
            case .neverMirrored: conn.isVideoMirrored = false
            }
            conn.automaticallyAdjustsVideoMirroring = false
        }
    }

}

extension CameraManager {
    enum RecordingMirrorPolicy {
        case followPreview   // ✅ 권장: 프리뷰가 미러면 파일도 미러
        case alwaysMirrored  // 항상 미러 저장
        case neverMirrored   // 절대 미러 저장 X (기존 방식)
    }
}
