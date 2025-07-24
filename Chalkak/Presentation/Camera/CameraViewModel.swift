//
//  CameraViewModel.swift
//  Chalkak
//
//  Created by 정종문 on 7/12/25.
//

import AVFoundation
import Combine
import CoreMotion
import Foundation
import Photos
import SwiftData
import SwiftUI

class CameraViewModel: ObservableObject {
    private let model: CameraManager
    let session: AVCaptureSession
    private var horizontalLevelCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    // 비디오 저장 완료 이벤트를 View로 전달
    let videoSavedPublisher = PassthroughSubject<URL, Never>()

    @Published var isTimerRunning = false
    @Published var showingTimerControl = false
    @Published var selectedTimerDuration: TimerOptions = .off

    @Published var showingCameraControl = false
    @Published var torchMode: TorchMode = .off
    @Published var isGrid = false
    @Published var isHorizontalLevelActive = false {
        didSet {
            if isHorizontalLevelActive {
                startObservingTilt()
            } else {
                stopObservingTilt()
            }
        }
    }

    @Published var isHorizontal = false

    @Published var cameraPostion: AVCaptureDevice.Position = .back {
        didSet {
            isUsingFrontCamera = (cameraPostion == .front)
        }
    }

    @Published var isRecording = false
    @Published var recordingTime = 0

    @Published var timerCountdown = 0

    @Published var showingZoomControl = false
    @Published var zoomScale: CGFloat = 1.0
    @Published var isUsingFrontCamera: Bool = false

    // 줌 범위  수정 가능
    var minZoomScale: CGFloat { 0.5 }
    var maxZoomScale: CGFloat { 6.0 }

    // 현재 카메라 타입 표시
    var currentCameraTypeSymbol: String {
        if zoomScale < 1.0 {
            return "0.5×" // 울트라 와이드
        } else if zoomScale <= 2.0 {
            return "1×" // 와이드
        } else {
            return "2×" // 망원
        }
    }

    private var timer: Timer?
    private var timerCountdownTimer: Timer?
    private var dataCollectionTimer: Timer?
    /// 녹화 시작 시간(실제 시간 기록용)
    private var recordingStartDate: Date?
    var timeStampedTiltList: [TimeStampedTilt] = []
    @Published var tiltCollector = TiltDataCollector()

    var formattedTime: String {
        let minutes = recordingTime / 60
        let seconds = recordingTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - init

    init() {
        model = CameraManager()
        session = model.session

        model.$isRecording
            .assign(to: &$isRecording)

        // 비디오 저장상태 구독
        model.savedVideoInfo
            .sink { [weak self] url in
                self?.videoSavedPublisher.send(url)
            }
            .store(in: &cancellables)

        loadSavedSettings()

        configure()

        // 저장되어있는 줌스케일 적용
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.model.setZoomScale(self.zoomScale)
        }
    }

    func switchCameraControls() {
        showingCameraControl.toggle()
    }

    func configure() {
        model.requestAndCheckPermissions()
    }

    func toggleTimerOption() {
        showingTimerControl.toggle()
    }

    func selectTimer(_ duration: TimerOptions) {
        selectedTimerDuration = duration
    }

    private func startTimerCountdown() {
        isTimerRunning = true
        timerCountdown = selectedTimerDuration.rawValue

        timerCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            self.timerCountdown -= 1

            if self.timerCountdown <= 0 {
                self.timerCountdownTimer?.invalidate()
                self.timerCountdownTimer = nil
                self.isTimerRunning = false

                // 타이머 완료 후 녹화 시작
                DispatchQueue.main.async {
                    self.executeVideoRecording()
                }
            }
        }
    }

    func focusAtPoint(_ point: CGPoint) {
        model.focusAtPoint(point)
    }

    func switchTorch() {
        torchMode.toggle()
        model.setTorchMode(torchMode)
    }

    func switchGrid() {
        isGrid.toggle()
    }

    func switchHorizontalLevel() {
        isHorizontalLevelActive.toggle()
    }

    private func startObservingTilt() {
        horizontalLevelCancellable = tiltCollector.$gravityX
            .sink { [weak self] gravityX in
                self?.isHorizontal = abs(gravityX) < 0.05
            }
    }

    /// 수평 감지 구독 제거
    private func stopObservingTilt() {
        horizontalLevelCancellable?.cancel()
        horizontalLevelCancellable = nil
    }

    func toggleZoomControl() {
        // 전면 카메라에서 줌 제어 비활성화
        guard !isUsingFrontCamera else { return }
        showingZoomControl.toggle()
    }

    func selectZoomScale(_ scale: CGFloat) {
        guard !isUsingFrontCamera else { return }
        guard !scale.isNaN, !scale.isInfinite else { return }

        let safeScale = max(minZoomScale, min(maxZoomScale, scale))
        zoomScale = safeScale
        model.setZoomScale(safeScale)
    }

    func startVideoRecording() {
        showingCameraControl = false
        // 타이머설정여부 -> 타이머 시작
        if selectedTimerDuration != .off {
            startTimerCountdown()
        } else {
            executeVideoRecording()
        }
    }

    private func executeVideoRecording() {
        model.startRecording()
        isRecording = true

        // 녹화 시작 시간 기록
        recordingStartDate = Date()
        // 틸트 데이터 초기화
        timeStampedTiltList.removeAll()

        // 타이머 시작
        startRecordingTimer()
        startDataCollectionTimer()
    }

    func stopVideoRecording() {
        // 타이머 카운트다운 취소
        if isTimerRunning {
            cancelTimerCountdown()
            return
        }

        model.stopRecording()
        isRecording = false
        stopRecordingTimer()
        stopDataCollectionTimer()
        recordingTime = 0
    }

    private func cancelTimerCountdown() {
        timerCountdownTimer?.invalidate()
        timerCountdownTimer = nil
        isTimerRunning = false
        timerCountdown = 0
    }

    private func startRecordingTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.recordingTime += 1
        }
    }

    /// Tilt 데이터 수집용 1/3초 타이머
    private func startDataCollectionTimer() {
        dataCollectionTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 3.0, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }

            if self.isRecording, let startDate = recordingStartDate {
                // 경과 시간 계산
                let recordingTime = Date().timeIntervalSince(startDate)

                // 기울기 값 가져오기
                let currentTilt = Tilt(degreeX: tiltCollector.gravityX, degreeZ: tiltCollector.gravityZ)

                timeStampedTiltList.append(.init(time: recordingTime, tilt: currentTilt))
            }
        })
    }

    private func stopRecordingTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func stopDataCollectionTimer() {
        dataCollectionTimer?.invalidate()
        timer = nil
    }

    private func resetRecordingTimer() {
        timer?.invalidate()
        timer = nil
        recordingTime = 0
    }

    func changeCamera() {
        // 후면->전면 전환시 : 현재 줌 저장 후 전면카메라로 전환
        if cameraPostion == .back {
            // 후면카메라 줌상태 저장 (UserDefaults)
            UserDefaults.standard.set(zoomScale, forKey: "backCameraZoomScale")
            showingZoomControl = false
            zoomScale = 1.0
        }

        cameraPostion = cameraPostion == .back ? .front : .back
        model.switchCamera(to: cameraPostion)

        // 전면->후면 전환시 : 이전에 저장된 후면카메라 줌 복원
        if cameraPostion == .back {
            let savedZoom = UserDefaults.standard.object(forKey: "backCameraZoomScale") as? CGFloat ?? 1.0
            zoomScale = savedZoom
            model.setZoomScale(savedZoom)
        }
    }

    func setBoundingBoxUpdateHandler(_ handler: @escaping ([CGRect]) -> Void) {
        model.onMultiBoundingBoxUpdate = handler
    }

    func saveCameraSettingToUserDefaults() -> CameraSetting {
        let setting = CameraSetting(
            zoomScale: zoomScale,
            isGridEnabled: isGrid,
            isFrontPosition: isUsingFrontCamera,
            timerSecond: selectedTimerDuration.rawValue
        )

        UserDefaults.standard.set(isGrid, forKey: UserDefaultKey.isGridOn)
        UserDefaults.standard.set(zoomScale, forKey: UserDefaultKey.zoomScale)
        UserDefaults.standard.set(selectedTimerDuration.rawValue, forKey: UserDefaultKey.timerSecond)
        UserDefaults.standard.set(setting.isFrontPosition, forKey: UserDefaultKey.isFrontPosition)

        return setting
    }

    private func loadSavedSettings() {
        let savedGridOn = UserDefaults.standard.bool(forKey: UserDefaultKey.isGridOn)
        let savedZoomScale = UserDefaults.standard.object(forKey: UserDefaultKey.zoomScale) as? CGFloat ?? 1.0
        let savedTimer = UserDefaults.standard.integer(forKey: UserDefaultKey.timerSecond)
        let savedIsFront = UserDefaults.standard.bool(forKey: UserDefaultKey.isFrontPosition)

        // 상태에 반영
        isGrid = savedGridOn
        zoomScale = savedZoomScale
        selectedTimerDuration = TimerOptions(rawValue: savedTimer) ?? .off
        cameraPostion = savedIsFront ? .front : .back
    }
}
