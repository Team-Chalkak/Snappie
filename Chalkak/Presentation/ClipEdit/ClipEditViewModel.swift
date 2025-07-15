//
//  ClipEditViewModel.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//
import Foundation
import SwiftData
import AVFoundation
import UIKit

/// 클립 편집 뷰모델
final class ClipEditViewModel: ObservableObject {
    private var modelContext: ModelContext?
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

    var clipURL: URL

    init(context: ModelContext?, clipURL: URL) {
        self.modelContext = context
        self.clipURL = clipURL
        setupPlayer()
    }

    deinit {
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
        }
        debounceTimer?.invalidate()
    }

    func updateContext(_ context: ModelContext) {
        self.modelContext = context
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
}
