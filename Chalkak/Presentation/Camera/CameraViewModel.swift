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
    private var modelContext: ModelContext?
    private let model: CameraManager
    let session: AVCaptureSession

    @Published var isTimerRunning = false
    @Published var showingCameraControl = false
    @Published var isTorch = false
    @Published var isSilentModeOn = false
    @Published var cameraPostion: AVCaptureDevice.Position = .back
    @Published var isRecording = false
    @Published var recordingTime = 0
    private var timer: Timer?
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

    func configure() {
        model.requestAndCheckPermissions()
    }

    func switchCameraControls() {
        showingCameraControl.toggle()
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
        model.startRecording()
        isRecording = true
        startRecordingTimer()
    }

    func stopVideoRecording() {
        model.stopRecording()
        isRecording = false
        stopRecordingTimer()
        recordingTime = 0
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

    func changeCamera() {
        cameraPostion = cameraPostion == .back ? .front : .back
        model.switchCamera(to: cameraPostion)
    }

    func updateContext(_ context: ModelContext) {
        modelContext = context
    }
}
