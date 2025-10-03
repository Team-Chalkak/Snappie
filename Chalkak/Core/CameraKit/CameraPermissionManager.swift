//
//  CameraPermissionManager.swift
//  Chalkak
//
//  Created by bishoe01 on 10/3/25.
//

import AVFoundation
import SwiftUI

class CameraPermissionManager: ObservableObject {
    @Published var showOnboarding = !UserDefaults.standard.bool(forKey: UserDefaultKey.hasCompletedOnboarding)
    // 앱 실행 시 카메라 화면에서 카메라, 마이크 권한 체크
    @Published var videoAuthorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published private(set) var audioAuthorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var permissionState: PermissionState = .none
    @Published var showPermissionSheet: Bool = false
    private var isRequestingPermissions = false
    private var audioRecordPermission = AVAudioApplication.recordPermission.undetermined

    func currentMicPermission() -> AVAudioApplication.recordPermission {
        return AVAudioApplication.shared.recordPermission
    }

    private func mapToAVAuthorization(_ record: AVAudioApplication.recordPermission) -> AVAuthorizationStatus {
        switch record {
        case .granted: return .authorized
        case .denied: return .denied
        case .undetermined: return .notDetermined
        @unknown default: return .denied
        }
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

    @MainActor
    func requestPermissions() {
        guard !isRequestingPermissions else { return }
        isRequestingPermissions = true

        checkPermissions()

        requestCameraPermission { [weak self] in
            self?.requestMicPermission { [weak self] in
                self?.finishPermissionRequest()
            }
        }
    }

    @MainActor
    private func requestCameraPermission(completion: @escaping () -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] _ in
                self?.videoAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
                completion()
            }
        default:
            videoAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            completion()
        }
    }

    @MainActor
    private func requestMicPermission(completion: @escaping () -> Void) {
        let currentPermission = currentMicPermission()

        if currentPermission == .undetermined {
            AVAudioApplication.requestRecordPermission { [weak self] _ in
                self?.audioRecordPermission = self?.currentMicPermission() ?? .undetermined
                self?.audioAuthorizationStatus = self?.mapToAVAuthorization(self?.audioRecordPermission ?? .undetermined) ?? .notDetermined
                completion()
            }
        } else {
            audioRecordPermission = currentPermission
            audioAuthorizationStatus = mapToAVAuthorization(currentPermission)
            completion()
        }
    }

    @MainActor
    private func finishPermissionRequest() {
        isRequestingPermissions = false
        checkPermissions()
    }

    func refreshPermissionSheet() {
        checkPermissions()

        if !isRequestingPermissions {
            showPermissionSheet = (permissionState != .both)
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: UserDefaultKey.hasCompletedOnboarding)
        showOnboarding = false
        checkPermissions()
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
