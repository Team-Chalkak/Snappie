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

final class ClipEditViewModel: ObservableObject {
    private var modelContext: ModelContext?
    private var asset: AVAsset?
    private var imageGenerator: AVAssetImageGenerator?
    private var timeObserverToken: Any?
    private var debounceTimer: Timer?

    private let thumbnailCount = 10  // 썸네일 개수는 여기서만 관리
    
    @Published var player: AVPlayer?
    @Published var startPoint: Double = 0
    @Published var endPoint: Double = 0
    @Published var duration: Double = 0
    @Published var thumbnails: [UIImage] = []
    @Published var isPlaying = false

    // 더미 영상 경로
    private let dummyURL: URL? = Bundle.main.url(forResource: "sample-video", withExtension: "mov")

    init(context: ModelContext?) {
        self.modelContext = context
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
        guard let url = dummyURL else {
            print("❌ dummyURL is nil")
            return
        }

        let asset = AVAsset(url: url)
        self.asset = asset

        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
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
                    let uiImage = UIImage(cgImage: cgImage)
                    images.append(uiImage)
                }
            } catch {
                print("⚠️ Failed to generate thumbnail at \(i): \(error)")
            }
        }

        self.thumbnails = images
    }

    func updateStart(_ value: Double) {
        startPoint = value
        seek(to: value)
    }

    func updateEnd(_ value: Double) {
        endPoint = value
        seek(to: value)
    }

    func seek(to time: Double) {
        player?.seek(
            to: CMTime(seconds: time, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
    }
    
    func togglePlayback() {
        isPlaying.toggle()
        if isPlaying {
            playPreview()
        } else {
            player?.pause()
        }
    }
    
    func playPreview() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        
        player?.seek(to: CMTime(seconds: startPoint, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            guard let self = self else { return }
            
            self.player?.play()
            self.isPlaying = true
            
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

