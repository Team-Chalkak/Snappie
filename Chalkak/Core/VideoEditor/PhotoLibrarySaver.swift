//
//  PhotoLibrarySaver.swift
//  Chalkak
//
//  Created by 석민솔 on 7/17/25.
//

import Foundation
import Photos

/// 사진 라이브러리에 비디오를 저장하는 기능을 합니다
struct PhotoLibrarySaver {
    /// 비디오를 사진 라이브러리에 저장합니다.
    /// - Returns: 저장 성공 -> true, 권한 허용이 되어있지않거나, 저장 실패 -> false
    @MainActor
    func saveVideoToLibrary(videoURL: URL) async -> Bool {
        let authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        switch authorizationStatus {
        case .notDetermined:
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            if status == .authorized || status == .limited {
                return await performVideoSave(videoURL: videoURL)
            } else {
                print("라이브러리 권한 거부")
                return false
            }
        case .authorized, .limited:
            return await performVideoSave(videoURL: videoURL)
        default:
            print("라이브러리 접근 권한 없음")
            return false
        }
    }

    /// 실제 비디오 저장 작업을 수행합니다.
    /// - Returns: 저장 성공 -> true, 권한 허용이 되어있지않거나, 저장 실패 -> false
    private func performVideoSave(videoURL: URL) async -> Bool {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }
            print("동영상 저장 성공")
            return true
        } catch {
            print("동영상 저장 에러: \(error.localizedDescription)")
            return false
        }
    }
}
