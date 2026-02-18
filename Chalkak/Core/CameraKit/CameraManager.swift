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

    @Published private(set) var isPreviewMirrored: Bool = false

    var onPreviewMirroringChanged: ((Bool) -> Void)?
    private weak var previewLayer: AVCaptureVideoPreviewLayer?

    // 정책(원하면 설정 화면에서 바꿀 수 있게)
    var recordingMirrorPolicy: RecordingMirrorPolicy = .followPreview
    // 현재 파일이 미러로 저장되고 있는지(Clip에 넘겨 기록용)
    @Published private(set) var isRecordingMirrored: Bool = false

    override init() {
        super.init()
    }

    deinit {
        session.stopRunning()
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

            // 카메라 설정 (초점, 노출, 줌 포함)
            try configureCameraSettings(for: device)

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

        // 줌 설정 (후면 카메라 한정)
        if device.position == .back {
            let minZoom = device.minAvailableVideoZoomFactor
            let maxZoom = device.maxAvailableVideoZoomFactor
            device.videoZoomFactor = max(minZoom, min(backCameraZoomScale * 2.0, maxZoom))

            DispatchQueue.main.async { [weak self] in
                self?.currentZoomScale = self?.backCameraZoomScale ?? 1.0
            }
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

    /// 줌 배율 스무스하게 전환 (프리셋 버튼용 0.5,1,2)
    func smoothSetZoomScale(_ scale: CGFloat) {
        setZoomScale(scale, rate: 8.0)
    }

    /// 줌 배율 설정
    /// - Parameters:
    ///   - scale: UI 줌 배율 (0.5 ~ 6.0)
    ///   - rate: ramp 속도로 조정을 해주는데, 일관성을 위해 즉시반영(슬라이더/핀치 할때만)은. nil로 처리를 해줬고, 값이 있으면 스무스하게 전환되는 것을 의도했습니다.(프리셋버튼 0.5,1,2) rate는 높을수록 반응이 빠름
    func setZoomScale(_ scale: CGFloat, rate: Float? = nil) {
        guard let device = videoDeviceInput?.device else { return }
        guard device.position == .back else { return }

        let minZoom = device.minAvailableVideoZoomFactor
        let maxZoom = device.maxAvailableVideoZoomFactor
        let targetZoom = max(minZoom, min(scale * 2.0, maxZoom))

        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }

            if let rate {
                device.ramp(toVideoZoomFactor: targetZoom, withRate: rate)
            } else {
                device.videoZoomFactor = targetZoom
            }
        } catch {
            print("줌 조정 에러 \(error)")
        }

        currentZoomScale = scale
        backCameraZoomScale = scale
    }

    /// 카메라 세션 시작
    func startSession() {
        // 권한은 외부(PermissionManager)에서 체크됨
        if session.inputs.isEmpty {
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

        // 시스템이 전/후면 전환/방향 등에 따라 적절히 판단하도록
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

        if isPreviewMirrored != mirrored {
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

    func updateRecordingMirroring() {
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

        // videoOutput도 파일 좌표계와 맞추기 위한 동일 처리
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
        case followPreview // 권장: 프리뷰가 미러면 파일도 미러
        case alwaysMirrored // 항상 미러 저장
        case neverMirrored // 절대 미러 저장 X (기존 방식)
    }
}
