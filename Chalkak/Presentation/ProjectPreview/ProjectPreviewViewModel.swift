//
//  ProjectPreviewViewModel.swift
//  Chalkak
//
//  Created by 석민솔 on 7/17/25.
//

import AVFoundation
import Foundation

/// ProjectPreviewView의 뷰모델
final class ProjectPreviewViewModel: ObservableObject {
    // MARK: - Properties
    // input properties
    let editableClips: [EditableClip]
    var onExport: (() async -> URL?)?

    // Property Wrappers
    @Published var player: AVQueuePlayer?
    @Published var isExporting: Bool = false

    private var finalVideoURL: URL?
    private var playerLooper: AVPlayerLooper?
    
    private let videoManager = VideoManager()
    private let photoLibrarySaver = PhotoLibrarySaver()


    // MARK: - init
    init(editableClips: [EditableClip]) {
        self.editableClips = editableClips
    }
    
    
    // MARK: - Methods
    func exportAndSetPlayer() async -> Bool {
        finalVideoURL = await exportEditedVideoToPhotos()

        if let finalVideoURL {
            await setupLoopingPlayer(url: finalVideoURL)
        }

        return finalVideoURL != nil
    }
    
    @MainActor
    func exportEditedVideoToPhotos() async -> URL? {
        isExporting = true
        defer { isExporting = false }

        do {
            // videoManager는 processAndSaveVideo(clips:)를 구현해 두세요.
            // 클립 배열을 받아 합쳐진 URL을 리턴하도록 만듭니다.
            let finalURL = try await videoManager.processAndSaveVideo(clips: editableClips)
            let success = await photoLibrarySaver.saveVideoToLibrary(videoURL: finalURL)

            return success ? finalURL : nil
        } catch {
            print("내보내기 실패:", error)
            return nil
        }

    }

    @MainActor
    func setupLoopingPlayer(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player = AVQueuePlayer(playerItem: playerItem)

        // 무한 반복 설정
        guard let player else {
            return
        }
        playerLooper = AVPlayerLooper(
            player: player,
            templateItem: playerItem
        )

        player.play()
    }

    /// 합본 영상을 임시 저장소에서 제거
    func cleanupTemporaryVideoFile() async {
        guard let finalVideoURL else { return }
        try? FileManager.default.removeItem(at: finalVideoURL)
    }
}
