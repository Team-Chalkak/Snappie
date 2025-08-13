//
//  ProjectPreviewViewModel.swift
//  Chalkak
//
//  Created by 석민솔 on 7/17/25.
//

import AVFoundation
import Foundation
import SwiftData

/// ProjectPreviewView의 뷰모델
final class ProjectPreviewViewModel: ObservableObject {
    // MARK: - Properties
    private var finalVideoURL: URL?
    let photoLibrarySaver = PhotoLibrarySaver()
    
    @Published var player: AVPlayer?
    @Published var isMerging: Bool = false
    @Published var videoManager = VideoManager()
    
    /// 영상 병합 및 플레이어 세팅
    @MainActor
    func startMerging() async {
        isMerging = true
        do {
            let url = try await videoManager.processAndSaveVideo()
            self.finalVideoURL = url
            self.player = AVPlayer(url: url)
            self.player?.play()
        } catch {
            print("⚠️ mergeVideo 실패: \(error.localizedDescription)")
        }
        isMerging = false 
    }
    
    // MARK: - Methods
    /// 비디오를 사진 라이브러리에 저장
    func exportToPhotos() async {
        guard let finalVideoURL else { return }
        await photoLibrarySaver.saveVideoToLibrary(videoURL: finalVideoURL)
    }

    /// 합본 영상을 임시 저장소에서 제거
    func cleanupTemporaryVideoFile() async {
        guard let finalVideoURL else { return }
        try? FileManager.default.removeItem(at: finalVideoURL)
    }
    
    /// UserDefaults에서 currentProjectID 제거
    func clearCurrentProjectID() {
        UserDefaults.standard.set(nil, forKey: UserDefaultKey.currentProjectID)
    }
}
