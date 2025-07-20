//
//  VideoManager.swift
//  Chalkak
//
//  Created by 석민솔 on 7/16/25.
//

import Foundation
import Photos

import Foundation
import Photos

/// 비디오 처리 및 저장을 담당하는 매니저 클래스
///
/// `VideoManager`는 여러 비디오 클립을 로드하고 병합하여 최종 비디오를 생성하는 역할을 합니다.
/// SwiftUI의 `ObservableObject`를 준수하여 처리 상태를 UI에 반영할 수 있습니다.
///
/// ## 사용 예시
///
/// ### 처리 상태에 따른 UI 업데이트
/// ```swift
/// struct VideoProcessingView: View {
///     @StateObject private var videoManager = VideoManager()
///
///     var body: some View {
///         VStack {
///             Text(videoManager.isProcessing ? "처리 중..." : "대기 중")
///
///             Button(action: {
///                 Task {
///                     await videoManager.processAndSaveVideo()
///                 }
///             }) {
///                 Text(videoManager.isProcessing ? "처리 중..." : "비디오 병합하기")
///             }
///             .disabled(videoManager.isProcessing)
///         }
///     }
/// }
/// ```
class VideoManager: ObservableObject {
    // MARK: - Properties
    /// 비디오 처리 진행 상태
    ///
    /// `true`일 때 비디오 처리가 진행 중이며, `false`일 때 처리가 완료되었거나 대기 중입니다.
    @Published var isProcessing = false
    
    private let videoLoader = VideoLoader()
    private let videoMerger = VideoMerger()
    
    // MARK: - Methods
    /// 비디오 클립들을 로드하고 병합하여 최종 비디오를 생성합니다.
    func processAndSaveVideo() async {
        isProcessing = true
        
        // defer를 통해 함수가 어떻게 종료되든 isProcessing을 false로 설정
        defer {
            isProcessing = false
        }
        
        // 1. 데이터 로드
        let clipList = await videoLoader.loadProjectClipList()
        
        guard !clipList.isEmpty else {
            print("클립이 없습니다")
            return
        }
        
        print("영상 합치기 시작 - 영상 개수: \(clipList.count)")
        
        do {
            // 2. 비디오 병합
            let finalVideoURL = try await VideoMerger().mergeVideos(from: clipList)
            
            // FIXME: 미리보기 네비게이션 구현하면서 이 파일에서 해당 갤러리 저장 로직은 삭제하기(ssol)
            // 3. (임시) 갤러리에 저장
            await saveVideoToLibrary(videoURL: finalVideoURL)

        } catch {
            print("영상 합치기 실패: \(error.localizedDescription)")
        }
    }
}

// FIXME: 미리보기 네비게이션 구현하면서 이 파일에서 해당 갤러리 저장 로직은 삭제될 예정(ssol)
// MARK: Photos 앱에 데이터 저장
extension VideoManager {
    /// 비디오를 사진 라이브러리에 저장합니다.
    @MainActor
    private func saveVideoToLibrary(videoURL: URL) async {
        let authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch authorizationStatus {
        case .notDetermined:
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            if status == .authorized || status == .limited {
                await performVideoSave(videoURL: videoURL)
            } else {
                print("라이브러리 권한 거부")
            }
        case .authorized, .limited:
            await performVideoSave(videoURL: videoURL)
        default:
            print("라이브러리 접근 권한 없음")
        }
    }
    
    /// 실제 비디오 저장 작업을 수행합니다.
    private func performVideoSave(videoURL: URL) async {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }
        } catch {
            print("동영상 저장 에러\(error.localizedDescription)")
        }
    }
}
