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
    // MARK: - Published Properties (UI State)
    // 뷰가 직접 구독하는 상태 변수들을 그룹화합니다.
    @Published var needsPermissionRequest = false
    @Published var isTimerRunning = false
    @Published var selectedTimerDuration: TimerOptions = .off
    @Published var showTimerFeedback: TimerOptions? = nil
    @Published var showingCameraControl = false
    @Published var torchMode: TorchMode = .off
    @Published var isGrid = false
    @Published var isHorizontalLevelActive = false {
        didSet { isHorizontalLevelActive ? startObservingTilt() : stopObservingTilt() }
    }
    @Published var isHorizontal = false
    @Published var cameraPostion: AVCaptureDevice.Position = .back {
        didSet { isUsingFrontCamera = (cameraPostion == .front) }
    }
    @Published var isRecording = false
    @Published var recordingTime = 0
    @Published var timerCountdown = 0
    @Published var showingZoomControl = false
    @Published var zoomScale: CGFloat = 1.0
    @Published var isUsingFrontCamera: Bool = false
    @Published var hasBadge: Bool = false
    @Published var showProjectSavedAlert: Bool = false
    @Published var lastZoomInteraction = Date() // 줌 슬라이더 타이머 로직을 위해 유지

    // MARK: - Core Dependencies & Models
    private let model: CameraManager
    private let swiftDataManager = SwiftDataManager.shared
    @Published var tiltCollector = TiltDataCollector()

    // MARK: Internal State
    let session: AVCaptureSession
    let videoSavedPublisher = PassthroughSubject<URL, Never>()
    var timeStampedTiltList: [TimeStampedTilt] = []

    private var cancellables = Set<AnyCancellable>()
    private var horizontalLevelCancellable: AnyCancellable?
    
    // Private Timers
    private var feedbackTimer: Timer?
    private var zoomSliderAutoHideTimer: Timer?
    private var recordingTimer: Timer?
    private var countdownTimer: Timer?
    private var dataCollectionTimer: Timer?
    private var recordingStartDate: Date?

    // MARK: - Computed Properties
    var minZoomScale: CGFloat { 0.5 }
    var maxZoomScale: CGFloat { 6.0 }
    var formattedTime: String { String(format: "%02d:%02d", recordingTime / 60, recordingTime % 60) }
    var currentTimerIcon: Icon { selectedTimerDuration.icon }
    var currentFlashIcon: Icon { torchMode.icon }
    private var hasRequiredPermissions: Bool { model.permissionState == .both }

    // MARK: - init
    init() {
        model = CameraManager()
        session = model.session

        model.$isRecording
            .assign(to: &$isRecording)

        model.savedVideoInfo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] url in
                self?.videoSavedPublisher.send(url)
            }
            .store(in: &cancellables)

        loadSavedSettings()

        Task { @MainActor in
            updateBadgeState()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.cameraSetupDelay) {
            self.model.setZoomScale(self.zoomScale)
        }
    }

    // MARK: - Camera Set
    func startCamera() { model.startSession() }
    func stopCamera() {
        if isRecording { stopVideoRecording() }
        model.stopSession()
    }

    func switchCameraControls() { showingCameraControl.toggle() }
    func focusAtPoint(_ point: CGPoint) { model.focusAtPoint(point) }
    func switchTorch() {
        torchMode.toggle()
        model.setTorchMode(torchMode)
    }
    func switchGrid() { isGrid.toggle() }
    func switchHorizontalLevel() { isHorizontalLevelActive.toggle() }
    func setBoundingBoxUpdateHandler(_ handler: @escaping ([CGRect]) -> Void) {
        model.onMultiBoundingBoxUpdate = handler
    }
    func toggleTimerOption() {
        selectedTimerDuration = selectedTimerDuration.next()
        guard selectedTimerDuration != .off else { return }

        feedbackTimer?.invalidate()
        showTimerFeedback = selectedTimerDuration
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.showTimerFeedback = nil
        }
    }

    // MARK: - Zoom Logic
    func toggleZoomControl() {
        guard !isUsingFrontCamera else { return }
        showingZoomControl.toggle()
        if showingZoomControl {
            startZoomSliderAutoHideTimer()
        } else {
            cancelZoomSliderAutoHideTimer()
        }
    }

    func selectZoomScale(_ scale: CGFloat) {
        guard !isUsingFrontCamera else { return }
        guard !scale.isNaN, !scale.isInfinite else { return }

        let safeScale = max(minZoomScale, min(maxZoomScale, scale))
        zoomScale = safeScale
        model.setZoomScale(safeScale)

        lastZoomInteraction = Date()
        if showingZoomControl { startZoomSliderAutoHideTimer() }
    }

    // MARK: - Recording Logic
    func startVideoRecording() {
        guard checkPermissionOrRequestSheet() else { return }
        showingCameraControl = false
        selectedTimerDuration != .off ? startTimerCountdown() : executeVideoRecording()
    }

    func stopVideoRecording() {
        if isTimerRunning { cancelTimerCountdown(); return }
        model.stopRecording()
        recordingTimer?.invalidate()
        recordingTimer = nil
        dataCollectionTimer?.invalidate()
        dataCollectionTimer = nil
        recordingTime = 0
    }

    private func executeVideoRecording() {
        guard checkPermissionOrRequestSheet() else { return }
        model.startRecording()
        recordingStartDate = Date()
        timeStampedTiltList.removeAll()
        startRecordingTimer()
        startDataCollectionTimer()
    }

    // MARK: - Timer Management
    private func startTimerCountdown() {
        isTimerRunning = true
        timerCountdown = selectedTimerDuration.rawValue
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.timerCountdown -= 1
            if self.timerCountdown <= 0 {
                self.cancelTimerCountdown()
                self.executeVideoRecording()
            }
        }
    }

    private func cancelTimerCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        isTimerRunning = false
        timerCountdown = 0
    }

    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.recordingTime += 1
        }
    }

    private func startDataCollectionTimer() {
        dataCollectionTimer = Timer.scheduledTimer(withTimeInterval: Self.dataCollectionInterval, repeats: true) { [weak self] _ in
            guard let self = self, let startDate = self.recordingStartDate else { return }
            let recordingTime = Date().timeIntervalSince(startDate)
            let currentTilt = Tilt(degreeX: self.tiltCollector.gravityX, degreeZ: self.tiltCollector.gravityZ)
            self.timeStampedTiltList.append(.init(time: recordingTime, tilt: currentTilt))
        }
    }

    private func startZoomSliderAutoHideTimer() {
        cancelZoomSliderAutoHideTimer()
        zoomSliderAutoHideTimer = Timer.scheduledTimer(withTimeInterval: Self.zoomSliderAutoHideInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if Date().timeIntervalSince(self.lastZoomInteraction) >= Self.zoomSliderAutoHideInterval {
                withAnimation(.easeInOut(duration: 0.3)) { self.showingZoomControl = false }
            }
        }
    }

    private func cancelZoomSliderAutoHideTimer() {
        zoomSliderAutoHideTimer?.invalidate()
        zoomSliderAutoHideTimer = nil
    }

    // MARK: - Tilt Observation
    private func startObservingTilt() {
        horizontalLevelCancellable = tiltCollector.gravityXPublisher.sink { [weak self] gravityX in
            self?.isHorizontal = abs(gravityX) < 0.05
        }
    }

    private func stopObservingTilt() {
        horizontalLevelCancellable?.cancel()
        horizontalLevelCancellable = nil
    }

    // MARK: - Settings Persistence
    func saveCameraSettings() {
        let setting = CameraSetting(
            zoomScale: zoomScale,
            isGridEnabled: isGrid,
            isFrontPosition: isUsingFrontCamera,
            timerSecond: selectedTimerDuration.rawValue
        )
        UserDefaults.standard.set(setting.isGridEnabled, forKey: UserDefaultKey.isGridOn)
        UserDefaults.standard.set(setting.zoomScale, forKey: UserDefaultKey.zoomScale)
        UserDefaults.standard.set(setting.timerSecond, forKey: UserDefaultKey.timerSecond)
        UserDefaults.standard.set(setting.isFrontPosition, forKey: UserDefaultKey.isFrontPosition)
    }

    private func loadSavedSettings() {
        isGrid = UserDefaults.standard.bool(forKey: UserDefaultKey.isGridOn)
        zoomScale = UserDefaults.standard.object(forKey: UserDefaultKey.zoomScale) as? CGFloat ?? 1.0
        selectedTimerDuration = TimerOptions(rawValue: UserDefaults.standard.integer(forKey: UserDefaultKey.timerSecond)) ?? .off
        cameraPostion = UserDefaults.standard.bool(forKey: UserDefaultKey.isFrontPosition) ? .front : .back
    }
    
    // MARK: - Camera Switching
    func changeCamera() {
        let newPosition: AVCaptureDevice.Position = cameraPostion == .back ? .front : .back

        if cameraPostion == .back { // to Front
            // 개선: 하드코딩된 문자열 키 대신 정의된 키를 사용합니다.
            // UserDefaultKey.swift 파일에 `static let backCameraZoomScale = "backCameraZoomScale"` 추가 필요
            UserDefaults.standard.set(zoomScale, forKey: UserDefaultKey.backCameraZoomScale)
            showingZoomControl = false
            zoomScale = 1.0
        }

        cameraPostion = newPosition
        model.switchCamera(to: cameraPostion)

        if cameraPostion == .back { // to Back
            let savedZoom = UserDefaults.standard.object(forKey: UserDefaultKey.backCameraZoomScale) as? CGFloat ?? 1.0
            zoomScale = savedZoom
            model.setZoomScale(savedZoom)
        }
    }

    // MARK: - Private Helpers
    private func checkPermissionOrRequestSheet() -> Bool {
        guard hasRequiredPermissions else { needsPermissionRequest = true; return false }
        return true
    }

    @MainActor
    func updateBadgeState() {
        hasBadge = !swiftDataManager.getUncheckedProjectsForBadge().isEmpty
    }

    @MainActor
    func showProjectSavedNotification() {
        showProjectSavedAlert = true
    }
}

// MARK: - UI Logic Extensions
// ViewModel의 부담을 줄이고 관련 코드를 모델과 가깝게 배치하기 위해 extension으로 분리합니다.
extension TorchMode {
    var icon: Icon {
        switch self {
        case .off: return .flashOff
        case .on: return .flashOn
        case .auto: return .flashAuto
        }
    }
}

extension TimerOptions {
    var icon: Icon {
        switch self {
        case .off: return .timerOff
        case .three: return .timer3sec
        case .five: return .timer5sec
        case .ten: return .timer10sec
        }
    }

    func next() -> TimerOptions {
        switch self {
        case .off: return .three
        case .three: return .five
        case .five: return .ten
        case .ten: return .off
        }
    }
}

// TiltDataCollector가 gravityXPublisher를 제공하도록 확장합니다.
extension TiltDataCollector {
    var gravityXPublisher: AnyPublisher<Double, Never> {
        $gravityX.eraseToAnyPublisher()
    }
}


// MARK: - Constants
// 하드코딩된 숫자들을 의미있는 상수로 변경
extension CameraViewModel {
    private static let cameraSetupDelay: TimeInterval = 0.5
    private static let zoomSliderAutoHideInterval: TimeInterval = 1.5
    private static let dataCollectionInterval: TimeInterval = 1.0 / 3.0
}
