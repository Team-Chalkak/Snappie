//
//  PermissionManager.swift
//  Chalkak
//
//  Created by bishoe01 on 12/25/25.
//

import AVFoundation
import Combine
import Foundation
import SwiftUI

@Observable
final class PermissionManager {
    // MARK: - Published Properties

    var videoAuthorizationStatus: AVAuthorizationStatus = .notDetermined
    private(set) var audioAuthorizationStatus: AVAuthorizationStatus = .notDetermined
    var permissionState: PermissionState = .none
    var showPermissionSheet: Bool = false

    // MARK: - Private Properties

    private var audioRecordPermission: AVAudioSession.RecordPermission = .undetermined
    private var isRequestingPermissions = false

    // MARK: - Initialization

    init() {
        checkPermissions()
    }

    // MARK: - Public Methods

    func checkPermissions() {
        videoAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        audioRecordPermission = currentMicPermission()
        audioAuthorizationStatus = mapToAVAuthorization(audioRecordPermission)
        updatePermissionState()
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

    // MARK: - Private Methods

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

            // CameraManager의 setUpCamera() 호출 제거
            // 권한 상태만 업데이트하고, 카메라 시작은 각 뷰에서 판단
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
}
