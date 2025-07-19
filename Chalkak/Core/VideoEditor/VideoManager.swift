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
    func processAndSaveVideo() async throws -> URL {
        isProcessing = true
        
        // defer를 통해 함수가 어떻게 종료되든 isProcessing을 false로 설정
        defer {
            isProcessing = false
        }
        
        // 1. 데이터 로드
        let clipList = await videoLoader.loadProjectClipList()
        
        guard !clipList.isEmpty else {
            print("클립이 없습니다")
            throw VideoMergerError.noVideosToMerge
        }
        
        print("영상 합치기 시작 - 영상 개수: \(clipList.count)")
        
        do {
            // 2. 비디오 병합
            let finalVideoURL = try await videoMerger.mergeVideos(from: clipList)
            
            return finalVideoURL

        } catch {
            print("영상 합치기 실패: \(error.localizedDescription)")
            throw VideoMergerError.exportFailed
        }
    }
}
