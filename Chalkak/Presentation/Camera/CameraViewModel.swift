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

class CameraViewModel: ObservableObject {
    private let model: CameraManager
    let session: AVCaptureSession

    @Published var isTimerRunning = false
    @Published var showingTimerControl = false
    @Published var selectedTimerDuration: TimerOptions = .off

    @Published var showingCameraControl = false
    @Published var isTorch = false
    @Published var isGrid = false

    @Published var cameraPostion: AVCaptureDevice.Position = .back
    @Published var isRecording = false
    @Published var recordingTime = 0

    @Published var timerCountdown = 0

    @Published var showingZoomControl = false
    @Published var zoomScale: CGFloat = 1.0

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

        configure()
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

    func switchGrid() {
        isGrid.toggle()
    }

    func toggleZoomControl() {
        showingZoomControl.toggle()
    }

    func selectZoomScale(_ scale: CGFloat) {
        // 안전성 검사
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
    
    func setBoundingBoxUpdateHandler(_ handler: @escaping ([CGRect]) -> Void) {
        model.onMultiBoundingBoxUpdate = handler
    }
}
