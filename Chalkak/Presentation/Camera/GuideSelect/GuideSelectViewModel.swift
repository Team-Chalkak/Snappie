//
//  GuideSelectViewModel.swift
//  Chalkak
//
//  Created by bishoe01 on 3/10/26.
//

import AVFoundation
import Foundation
import UIKit

/**
 GuideSelectViewModel: 가이드 프레임 선택 뷰모델

 GuideSelectView에서 사용하는 ViewModel로, 트리밍된 클립 구간 내에서
 가이드 프레임 위치(startPoint)를 탐색하는 기능을 담당합니다.

 ## 주요 기능
 - AVPlayer 초기화 및 트리밍 구간 설정 (trimmedClip)
 - 썸네일 생성 (트리밍 구간 기준)
 - startPoint 업데이트 및 seek
 - 재생/일시정지 토글

 ## ClipEditViewModel과의 차이
 - endPoint, 트리밍 핸들, playHead 관련 기능 없음
 - 저장/프로젝트 관련 기능 없음
 */
@MainActor
@Observable
final class GuideSelectViewModel {
    var clipURL: URL

    var player: AVPlayer = .init()
    var startPoint: Double = 0
    var duration: Double = 0
    var thumbnails: [UIImage] = []
    var isPlaying = false
    var previewImage: UIImage?
    var isPlayerReady: Bool = false
    var isRebuildingPlayer: Bool = false

    private var asset: AVAsset?
    private var imageGenerator: AVAssetImageGenerator?
    private var timeObserverToken: Any?
    private var trimOffset: Double = 0
    private var currentPlayTime: Double = 0
    private let thumbnailCount = 10

    init(clipURL: URL) {
        self.clipURL = clipURL
        setupPlayer()
    }

    private func setupPlayer() {
        isRebuildingPlayer = true
        isPlayerReady = false

        let asset = AVAsset(url: clipURL)
        self.asset = asset

        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero
        self.imageGenerator = imageGenerator

        Task { @MainActor in
            do {
                let durationCMTime = try await asset.load(.duration)
                let durationSeconds = CMTimeGetSeconds(durationCMTime)

                self.duration = durationSeconds

                guard durationSeconds > 0 else {
                    self.player.replaceCurrentItem(with: nil)
                    self.isPlayerReady = false
                    self.isRebuildingPlayer = false
                    return
                }

                self.startPoint = 0

                let item = AVPlayerItem(asset: asset)
                self.player.replaceCurrentItem(with: item)

                self.isPlayerReady = true
                self.isRebuildingPlayer = false

                await updatePreviewImage(at: self.startPoint)
                playPreview()

            } catch {
                print("Failed to load duration: \(error)")
                self.player.replaceCurrentItem(with: nil)
                self.isPlayerReady = false
                self.isRebuildingPlayer = false
            }
        }
    }

    /// 트리밍된 구간만 보여주도록 player 및 썸네일 설정
    func trimmedClip(trimStart: Double, trimEnd: Double) async {
        guard let imageGenerator = imageGenerator else { return }
        trimOffset = trimStart

        let trimmedDuration = trimEnd - trimStart
        startPoint = 0
        duration = trimmedDuration

        seek(to: 0)
        await updatePreviewImage(at: 0)

        thumbnails = []
        let interval = trimmedDuration / Double(thumbnailCount)

        let times = (0 ..< thumbnailCount).map { i in
            CMTime(seconds: trimStart + Double(i) * interval, preferredTimescale: 600)
        }

        do {
            for try await result in imageGenerator.images(for: times) {
                let cgImage = try result.image
                let uiImage = UIImage(cgImage: cgImage)
                thumbnails.append(uiImage)
            }
        } catch {
            print("썸네일트리밍 error \(error)")
        }
    }

    /// 특정 시간의 프레임을 추출하여 preview 이미지를 갱신
    func updatePreviewImage(at time: Double) async {
        guard let imageGenerator = imageGenerator else { return }
        let actualTime = time + trimOffset
        let cmTime = CMTime(seconds: actualTime, preferredTimescale: 600)
        do {
            let result = try await imageGenerator.image(at: cmTime)
            previewImage = UIImage(cgImage: result.image)
        } catch {
            print(error)
        }
    }

    /// 가이드 프레임 시작 지점을 갱신하고 프리뷰 이미지를 갱신
    func updateStart(_ value: Double) {
        startPoint = value
        if currentPlayTime < startPoint {
            seek(to: startPoint)
            Task { await updatePreviewImage(at: value) }
        }
    }

    /// AVPlayer를 지정된 시간으로 이동
    func seek(to time: Double, completion: (() -> Void)? = nil) {
        let actualTime = time + trimOffset
        let cmTime = CMTime(seconds: actualTime, preferredTimescale: 600)
        currentPlayTime = time
        player.seek(
            to: cmTime,
            toleranceBefore: .zero,
            toleranceAfter: .zero
        ) { _ in
            completion?()
        }
    }

    /// 재생/일시정지 상태 토글
    func togglePlayback() {
        isPlaying.toggle()
        isPlaying ? playPreview() : player.pause()
    }

    /// 썸네일 하나의 너비 계산
    func thumbnailUnitWidth(for thumbnailLineWidth: CGFloat) -> CGFloat {
        let count = max(thumbnails.count, 1)
        return thumbnailLineWidth / CGFloat(count)
    }

    /// startX 계산 (가이드 프레임 박스 위치)
    func startX(thumbnailLineWidth: CGFloat, handleWidth: CGFloat) -> CGFloat {
        guard duration > 0 else { return handleWidth }
        let ratio = startPoint / duration
        return handleWidth + ratio * thumbnailLineWidth
    }

    /// 트리밍 시작 시점부터 재생을 시작하고, 종료 시점에 도달하면 자동으로 정지
    func playPreview() {
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }

        let playerRef = player
        let trimOffset = self.trimOffset
        let endPoint = duration
        let startPoint = self.startPoint

        let currentTime = playerRef.currentTime()
        let currentTimeSeconds = CMTimeGetSeconds(currentTime)
        let actualStart = startPoint + trimOffset
        let actualEnd = endPoint + trimOffset
        let epsilon = 0.001

        func startPlaybackAndObserve() {
            playerRef.play()

            let token = playerRef.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 0.01, preferredTimescale: 600),
                queue: .main
            ) { time in
                let currentSeconds = CMTimeGetSeconds(time)
                let displaySeconds = currentSeconds - trimOffset
                let checkEnd = endPoint + trimOffset

                Task { @MainActor in
                    self.currentPlayTime = displaySeconds

                    if currentSeconds >= checkEnd {
                        playerRef.pause()
                        self.isPlaying = false

                        if let token = self.timeObserverToken {
                            playerRef.removeTimeObserver(token)
                            self.timeObserverToken = nil
                        }
                    }
                }
            }

            timeObserverToken = token
        }

        if currentTimeSeconds >= actualStart, currentTimeSeconds < (actualEnd - epsilon) {
            isPlaying = true
            startPlaybackAndObserve()
        } else {
            seek(to: startPoint) { [weak self] in
                guard let self else { return }
                self.isPlaying = true
                startPlaybackAndObserve()
            }
        }
    }
}
