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
    @ObservedObject var cameraPermissionManager = CameraPermissionManager()
    @ObservedObject var cameraConfigurationManger = CameraConfigurationManager()
    private var cancellables = Set<AnyCancellable>()

    // 앱 실행 시 카메라 화면에서 카메라, 마이크 권한 체크

    @Published var isRecording = false
    @Published var currentZoomScale: CGFloat = 1.0
    private var backCameraZoomScale: CGFloat = 1.0

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

    override init() {
        super.init()

        // PermissionManager에서 권한체크
        cameraPermissionManager.checkPermissions()

        if !cameraPermissionManager.showOnboarding, cameraPermissionManager.permissionState == .both {
            Task {
                await setUpCamera()
            }
        }

        cameraPermissionManager.$permissionState.sink { [weak self] newState in
            if newState == .both {
                if self?.session.inputs.isEmpty == true {
                    Task {
                        await self?.setUpCamera()
                    }
                }
            }
        }.store(in: &cancellables)

        cameraPermissionManager.$showPermissionSheet.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }

    deinit {
        session.stopRunning()
    }

    /// 비디오 저장 알림메소드
    func videoSaved(url: URL) {
        savedVideoInfo.send(url)
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
            try cameraConfigurationManger.configureCameraSettings(for: device, zoomScale: backCameraZoomScale)

            // 줌배율 UI반영
            DispatchQueue.main.async { [weak self] in
                self?.currentZoomScale = self?.backCameraZoomScale ?? 1.0
            }

            // 시작카메라 줌 배율 설정
            setZoomScale(backCameraZoomScale)

        } catch {
            print("카메라 설정 오류: \(error)")
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
            try cameraConfigurationManger.configureCameraSettings(for: device, zoomScale: backCameraZoomScale)

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
        cameraPermissionManager.checkPermissions()
        if cameraPermissionManager.permissionState == .both, session.inputs.isEmpty {
            Task { @MainActor in
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

    // Permission 관련 함수
    func completeOnboarding() {
        cameraPermissionManager.completeOnboarding()
    }

    func openSettings() {
        cameraPermissionManager.openSettings()
    }

    func requestPermissions() {
        cameraPermissionManager.requestPermissions()
    }

    func refreshPermissionSheet() {
        cameraPermissionManager.refreshPermissionSheet()
    }

    var permissionState: PermissionState {
        cameraPermissionManager.permissionState
    }

    var showOnboarding: Bool {
        cameraPermissionManager.showOnboarding
    }

    var showPermissionSheet: Bool {
        get { cameraPermissionManager.showPermissionSheet }
        set { cameraPermissionManager.showPermissionSheet = newValue }
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
