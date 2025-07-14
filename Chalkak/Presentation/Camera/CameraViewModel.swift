//
//  CameraViewModel.swift
//  Chalkak
//
//  Created by 정종문 on 7/12/25.
//

import AVFoundation
import Foundation
import Photos
import SwiftData
import SwiftUI

enum TimerOptions: Int, CaseIterable {
    case off = 0
    case three = 3
    case five = 5
    case ten = 10

    var displayText: String {
        switch self {
        case .off: return "해제"
        case .three: return "3초"
        case .five: return "5초"
        case .ten: return "10초"
        }
    }
}

class CameraViewModel: ObservableObject {
    private var modelContext: ModelContext?
    private let model: CameraManager
    let session: AVCaptureSession

    @Published var isTimerRunning = false
    @Published var showingTimerControl = false
    @Published var selectedTimerDuration: TimerOptions = .off

    @Published var showingCameraControl = false
    @Published var isTorch = false

    @Published var isSilentModeOn = false
    @Published var cameraPostion: AVCaptureDevice.Position = .back
    @Published var isRecording = false
    @Published var recordingTime = 0

    @Published var timerCountdown = 0
    private var timer: Timer?
    private var timerCountdownTimer: Timer?
    var formattedTime: String {
        let minutes = recordingTime / 60
        let seconds = recordingTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    init(context: ModelContext?) {
        model = CameraManager()
        session = model.session
        modelContext = context

        model.$isRecording
            .assign(to: &$isRecording)
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

    func switchTorch() {
        isTorch.toggle()
        model.setTorchMode(isTorch)
    }

    func switchSilent() {
        isSilentModeOn.toggle()
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
        print("녹화시작")
        model.startRecording()
        isRecording = true
        startRecordingTimer()
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

    private func stopRecordingTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func resetRecordingTimer() {
        timer?.invalidate()
        timer = nil
        recordingTime = 0
    }

    func changeCamera() {
        cameraPostion = cameraPostion == .back ? .front : .back
        model.switchCamera(to: cameraPostion)
    }

    func updateContext(_ context: ModelContext) {
        modelContext = context
    }
}
