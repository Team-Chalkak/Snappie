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
    private let swiftDataManager = SwiftDataManager.shared

    // 비디오 저장 완료 이벤트를 View로 전달
    let videoSavedPublisher = PassthroughSubject<URL, Never>()

    private var hasRequiredPermissions: Bool {
        model.permissionState == .both
    }

    // 권한 요청 시트 띄워주는 변수
    @Published var needsPermissionRequest = false

    /// 권한 체크 후 필요시 권한 요청 시트 표시로직
    /// - Returns: 권한이 여부에 따라 - 권한 요청시트 트리거
    private func checkPermissionOrRequestSheet() -> Bool {
        guard hasRequiredPermissions else {
            needsPermissionRequest = true
            return false
        }
        return true
    }

    @Published var isTimerRunning = false
    @Published var selectedTimerDuration: TimerOptions = .off
    @Published var showTimerFeedback: TimerOptions? = nil // 타이머 설정 피드백 표시
    private var feedbackTimer: Timer? // 타이머 피드백 라벨 1초 유지를 위한 타이머

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
    @Published var hasBadge: Bool = false
    @Published var showProjectSavedAlert: Bool = false

    // 줌 슬라이더 조절이 끝났을시 자동으로 숨김처리를 하기위한 타이머
    private var zoomSliderAutoHideTimer: Timer?
    @Published var lastZoomInteraction = Date()

    // 줌 범위  수정 가능
    var minZoomScale: CGFloat { 0.5 }
    var maxZoomScale: CGFloat { 6.0 }

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

        // 뱃지 상태 초기화
        Task { @MainActor in
            updateBadgeState()
        }

        // 저장되어있는 줌스케일 적용
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.model.setZoomScale(self.zoomScale)
        }
    }

    func switchCameraControls() {
        showingCameraControl.toggle()
    }

    /// 카메라 세션 시작
    func startCamera() {
        model.startSession()
    }

    /// 카메라 세션 중지
    func stopCamera() {
        // 녹화중이면 녹화 중지
        if isRecording {
            stopVideoRecording()
        }
        model.stopSession()
    }

    func toggleTimerOption() {
        switch selectedTimerDuration {
        case .off:
            selectedTimerDuration = .three
        case .three:
            selectedTimerDuration = .five
        case .five:
            selectedTimerDuration = .ten
        case .ten:
            selectedTimerDuration = .off
        }

        // 설정시 피드백 표시
        if selectedTimerDuration != .off {
            feedbackTimer?.invalidate()

            showTimerFeedback = selectedTimerDuration

            // 1초 디졸브를 위한 타이머(타이머가 몇초 설정되었음을 알려주기 위한 숫자라벨)
            feedbackTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
                self?.showTimerFeedback = nil
            }
        }
    }

    var currentTimerIcon: Icon {
        switch selectedTimerDuration {
        case .off:
            return .timerOff
        case .three:
            return .timer3sec
        case .five:
            return .timer5sec
        case .ten:
            return .timer10sec
        }
    }

    var currentFlashIcon: Icon {
        switch torchMode {
        case .off:
            return .flashOff
        case .on:
            return .flashOn
        case .auto:
            return .flashAuto
        }
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

        // 줌슬라이더 표시되는 순간부터 자동 숨김을 위한 1.5초 타이머 시작
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

        // 줌 스케일 변경 시 상호작용 시간 업데이트하고 타이머 재시작
        lastZoomInteraction = Date()
        if showingZoomControl {
            startZoomSliderAutoHideTimer()
        }
    }

    func startVideoRecording() {
        // 녹화버튼이 권한이 없으면 권한 요청트리거하는 버튼으로 바뀜
        guard checkPermissionOrRequestSheet() else { return }

        showingCameraControl = false
        // 타이머설정여부 -> 타이머 시작
        if selectedTimerDuration != .off {
            startTimerCountdown()
        } else {
            executeVideoRecording()
        }
    }

    private func executeVideoRecording() {
        guard checkPermissionOrRequestSheet() else { return }

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
        dataCollectionTimer = nil
    }

    func changeCamera() {
        let newPosition: AVCaptureDevice.Position = cameraPostion == .back ? .front : .back

        // 후면->전면 전환시: 현재 줌 저장 후 전면카메라로 전환
        if cameraPostion == .back {
            // 후면카메라 줌상태 저장 (UserDefaults)
            UserDefaults.standard.set(zoomScale, forKey: "backCameraZoomScale")
            showingZoomControl = false
            zoomScale = 1.0
        }

        // 카메라 위치 변경 및 실제 카메라 전환
        cameraPostion = newPosition
        model.switchCamera(to: cameraPostion)

        // 전면->후면 전환시: 이전에 저장된 후면카메라 줌 복원
        if cameraPostion == .back {
            // 카메라 전환이 완료된 후 줌 스케일 복원
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

    /// 뱃지 상태 업데이트
    @MainActor
    func updateBadgeState() {
        let uncheckedProjects = SwiftDataManager.shared.getUncheckedProjectsForBadge()
        hasBadge = !uncheckedProjects.isEmpty
    }

    /// 프로젝트 저장 알림 표시
    @MainActor
    func showProjectSavedNotification() {
        showProjectSavedAlert = true
    }

    private func startZoomSliderAutoHideTimer() {
        // 기존 타이머 초기화
        cancelZoomSliderAutoHideTimer()

        // 1.5초 후 숨김처리
        zoomSliderAutoHideTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            // 마지막 상호작용으로부터 1.5초가 지났는지 확인
            let timeSinceLastInteraction = Date().timeIntervalSince(self.lastZoomInteraction)
            if timeSinceLastInteraction >= 1.5 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.showingZoomControl = false
                }
            }
        }
    }

    private func cancelZoomSliderAutoHideTimer() {
        zoomSliderAutoHideTimer?.invalidate()
        zoomSliderAutoHideTimer = nil
    }
}
