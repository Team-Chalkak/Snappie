//
//  ProjectPreviewViewModel.swift
//  Chalkak
//
//  Created by 석민솔 on 7/17/25.
//

import AVFoundation
import Foundation
import SwiftUI

/// ProjectPreviewView의 뷰모델
final class ProjectPreviewViewModel: ObservableObject {
    // MARK: - Properties
    // input properties
    let editableClips: [EditableClip]
    let exportMode: ExportMode
    var onExport: (() async -> URL?)?

    // Property Wrappers
    @Published var player: AVQueuePlayer?
    @Published var isExporting: Bool = false

    private var finalVideoURL: URL?
    private var playerLooper: AVPlayerLooper?

    private let videoManager = VideoManager()
    private let photoLibrarySaver = PhotoLibrarySaver()


    // MARK: - init
    init(editableClips: [EditableClip], exportMode: ExportMode = .combined) {
        self.editableClips = editableClips
        self.exportMode = exportMode
    }


    // MARK: - Methods
    func exportAndSetPlayer() async -> Bool {
        switch exportMode {
        case .combined:
            finalVideoURL = await exportEditedVideoToPhotos()
        case .sceneByScene:
            finalVideoURL = await exportSceneByScene()
        }

        if let finalVideoURL {
            await setupLoopingPlayer(url: finalVideoURL)
        }

        return finalVideoURL != nil
    }

    var loadingMessage: LocalizedStringKey {
        switch exportMode {
        case .combined:     return "영상을 내보내는 중..."
        case .sceneByScene: return "장면들을 내보내는 중..."
        }
    }

    @MainActor
    func exportEditedVideoToPhotos() async -> URL? {
        isExporting = true
        defer { isExporting = false }

        do {
            let finalURL = try await videoManager.processAndSaveVideo(clips: editableClips)
            let success = await photoLibrarySaver.saveVideoToLibrary(videoURL: finalURL)

            return success ? finalURL : nil
        } catch {
            print("내보내기 실패:", error)
            return nil
        }
    }

    @MainActor
    func exportSceneByScene() async -> URL? {
        isExporting = true
        defer { isExporting = false }

        do {
            // 병합 영상 생성 (미리보기용, Photos에 저장 안 함)
            let mergedURL = try await videoManager.processAndSaveVideo(clips: editableClips)

            // 각 클립 개별 저장
            for clip in editableClips {
                let clipURL = try await videoManager.processAndSaveVideo(clips: [clip])
                _ = await photoLibrarySaver.saveVideoToLibrary(videoURL: clipURL)
                // 단일 클립 시 VideoMerger가 원본 URL을 그대로 반환하므로 삭제 금지
            }

            return mergedURL
        } catch {
            print("장면별 내보내기 실패:", error)
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
