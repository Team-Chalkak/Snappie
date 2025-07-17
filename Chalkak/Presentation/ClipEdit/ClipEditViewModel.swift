//
//  ClipEditViewModel.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

import AVFoundation
import Foundation
import SwiftData
import UIKit

/// 클립 편집 뷰모델
final class ClipEditViewModel: ObservableObject {
    private var asset: AVAsset?
    private var imageGenerator: AVAssetImageGenerator?
    private var timeObserverToken: Any?
    private var debounceTimer: Timer?

    private let thumbnailCount = 10

    @Published var player: AVPlayer?
    @Published var startPoint: Double = 0
    @Published var endPoint: Double = 0
    @Published var duration: Double = 0
    @Published var thumbnails: [UIImage] = []
    @Published var isPlaying = false
    @Published var previewImage: UIImage?
    @Published var clipID: String? = nil
    
    @Published var videoManager = VideoManager()

    var clipURL: URL

    init(clipURL: URL) {
        self.clipURL = clipURL
        setupPlayer()
    }

    deinit {
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
        }
        debounceTimer?.invalidate()
    }

    private func setupPlayer() {
        let asset = AVAsset(url: clipURL)
        self.asset = asset

        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero
        self.imageGenerator = imageGenerator

        Task {
            do {
                let durationCMTime = try await asset.load(.duration)
                let durationSeconds = CMTimeGetSeconds(durationCMTime)

                await MainActor.run {
                    self.duration = durationSeconds
                    self.endPoint = durationSeconds
                    let playerItem = AVPlayerItem(asset: asset)
                    self.player = AVPlayer(playerItem: playerItem)
                }

                await generateThumbnails(for: asset)
                await updatePreviewImage(at: 0)

            } catch {
                print("⚠️ Failed to load duration: \(error)")
            }
        }
    }

    @MainActor
    private func generateThumbnails(for asset: AVAsset) async {
        thumbnails = []
        let interval = duration / Double(thumbnailCount)
        var images: [UIImage] = []

        for i in 0..<thumbnailCount {
            let time = CMTime(seconds: Double(i) * interval, preferredTimescale: 600)
            do {
                if let cgImage = try imageGenerator?.copyCGImage(at: time, actualTime: nil) {
                    images.append(UIImage(cgImage: cgImage))
                }
            } catch {
                print("⚠️ Thumbnail \(i) error: \(error)")
            }
        }
        self.thumbnails = images
    }

    @MainActor
    func updatePreviewImage(at time: Double) async {
        let time = CMTime(seconds: time, preferredTimescale: 600)
        do {
            if let cgImage = try imageGenerator?.copyCGImage(at: time, actualTime: nil) {
                previewImage = UIImage(cgImage: cgImage)
            }
        } catch {
            print("⚠️ Preview error at \(time): \(error)")
        }
    }

    func updateStart(_ value: Double) {
        startPoint = value
        Task { await updatePreviewImage(at: value) }
    }

    func updateEnd(_ value: Double) {
        endPoint = value
        Task { await updatePreviewImage(at: value) }
    }

    func seek(to time: Double) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func togglePlayback() {
        isPlaying.toggle()
        isPlaying ? playPreview() : player?.pause()
    }
    
    /// 트리밍 라인(타임라인)에서 각 프레임 썸네일 너비
    func thumbnailWidth(for totalWidth: CGFloat) -> CGFloat {
        guard thumbnails.count > 0 else { return 0 }
        return totalWidth / CGFloat(thumbnails.count)
    }

    /// 왼쪽 트리밍 핸들 위치
    func startX(for totalWidth: CGFloat) -> CGFloat {
        return CGFloat(startPoint / duration) * totalWidth
    }

    /// 오른쪽 트리밍 핸들 위치
    func endX(for totalWidth: CGFloat) -> CGFloat {
        return CGFloat(endPoint / duration) * totalWidth
    }

    /// 트리밍 핸들 사이 간격
    func trimmingWidth(for totalWidth: CGFloat) -> CGFloat {
        return endX(for: totalWidth) - startX(for: totalWidth)
    }
    
    func playPreview() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        player?.seek(to: CMTime(seconds: startPoint, preferredTimescale: 600)) { [weak self] _ in
            guard let self = self else { return }
            self.player?.play()
            self.timeObserverToken = self.player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.01, preferredTimescale: 600), queue: .main) { [weak self] time in
                guard let self = self else { return }
                if CMTimeGetSeconds(time) >= self.endPoint {
                    self.player?.pause()
                    self.isPlaying = false
                    if let token = self.timeObserverToken {
                        self.player?.removeTimeObserver(token)
                        self.timeObserverToken = nil
                    }
                }
            }
        }
    }
    
    /// `Project` 저장
    /// 첫번째 영상 촬영 시점에 Clip 먼저 저장한 후에 해당 데이터와 nil 상태인 guide를 함께 저장
    /// ProjectID는 UserDefault에도 저장되어 있습니다.
    @MainActor
    func saveProjectData() {
        let clip = saveClipData()
        let projectID = UUID().uuidString
        _ = SwiftDataManager.shared.createProject(id: projectID, guide: nil, clips: [clip])
        
        SwiftDataManager.shared.saveContext()
        UserDefaults.standard.set(projectID, forKey: "currentProjectID")
    }
    
    @MainActor
    func saveClipData() -> Clip {
        let clipID = UUID().uuidString
        self.clipID = clipID
        return SwiftDataManager.shared.createClip(
            id: clipID,
            videoURL: clipURL,
            startPoint: startPoint,
            endPoint: endPoint,
            tiltList: [],
            heightList: []
        )
    }
    
    @MainActor
    func appendClipToCurrentProject() {
        let clip = saveClipData()

        guard let projectID = UserDefaults.standard.string(forKey: "currentProjectID"),
              let project = SwiftDataManager.shared.fetchProject(byID: projectID) else {
            print("기존 Project를 찾을 수 없습니다.")
            return
        }

        project.clipList.append(clip)
        SwiftDataManager.shared.saveContext()
    }
    
    /// 작업하던 프로젝트의 영상 합치기
    func mergeVideo() async throws -> URL {
        try await self.videoManager.processAndSaveVideo()
    }
}
