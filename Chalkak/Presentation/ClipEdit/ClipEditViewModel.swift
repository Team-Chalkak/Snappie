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
    
    @Published var player: AVPlayer?
    @Published var startPoint: Double = 0
    @Published var endPoint: Double = 0
    @Published var duration: Double = 0
    
    @Published var thumbnails: [UIImage] = [] /// 트리밍 사진들
    
    //TODO: 더미데이터
    private let dummyURL: URL? = Bundle.main.url(forResource: "sample-video", withExtension: "mov")

    init(context: ModelContext?) {
        self.modelContext = context
        setupPlayer()
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

        Task {
            do {
                let durationCMTime = try await asset.load(.duration)
                let durationSeconds = CMTimeGetSeconds(durationCMTime)
                await MainActor.run {
                    self.duration = durationSeconds
                    self.endPoint = durationSeconds

                    let playerItem = AVPlayerItem(asset: asset)
                    self.player = AVPlayer(playerItem: playerItem)
                    
                    generateThumbnails()
                }
            } catch {
                print("⚠️ Failed to load duration: \(error)")
            }
        }
    }
    
    private func generateThumbnails() {
        guard let asset = asset else { return }

        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        let totalDuration = CMTimeGetSeconds(asset.duration)
        let interval = totalDuration / 20 // 20개 썸네일

        var times = [NSValue]()
        for i in 0..<20 {
            let time = CMTime(seconds: Double(i) * interval, preferredTimescale: 600)
            times.append(NSValue(time: time))
        }

        imageGenerator.generateCGImagesAsynchronously(forTimes: times) { _, cgImage, _, _, _ in
            if let cgImage = cgImage {
                let uiImage = UIImage(cgImage: cgImage)
                DispatchQueue.main.async {
                    self.thumbnails.append(uiImage)
                }
            }
        }
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
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
    }
}
