//
//  VideoPlayerService.swift
//  Chalkak
//
//  Created by bishoe01 on 1/9/26.
//

import AVFoundation
import Foundation

@Observable
final class VideoPlayerService {
    var player: AVPlayer?
    var isPlaying = false
    private var timeObserverToken: Any?

    /// AVPlayer를 지정된 시간으로 이동
    func seek(to time: Double, trimOffset: Double) {
        let actualTime = time + trimOffset
        player?.seek(
            to: CMTime(seconds: actualTime, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
    }

    /// 재생/일시정지
    func pause() {
        player?.pause()
        isPlaying = false
    }

    /// 재생/일시정지 토글
    func togglePlayback(
        startPoint: Double,
        endPoint: Double,
        trimOffset: Double,
        onPlayPreview: @escaping () -> Void
    ) {
        isPlaying.toggle()
        if isPlaying {
            onPlayPreview()
        } else {
            player?.pause()
        }
    }

    /// 트리밍 구간 재생
    func playPreview(
        startPoint: Double,
        endPoint: Double,
        trimOffset: Double,
        onSeek: @escaping (Double) -> Void
    ) {
        // 기존 observer 제거
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }

        let currentTime = player?.currentTime() ?? .zero
        let currentTimeSeconds = CMTimeGetSeconds(currentTime)

        let actualStart = startPoint + trimOffset
        let actualEnd = endPoint + trimOffset

        /// 재생을 시작하고 종료 시점을 감지하는 로직
        let startPlaybackAndObserve = { [weak self] in
            guard let self = self else { return }
            self.player?.play()
            self.timeObserverToken = self.player?.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 0.01, preferredTimescale: 600),
                queue: .main
            ) { [weak self] time in
                guard let self = self else { return }
                let currentSeconds = CMTimeGetSeconds(time)

                let checkEndPoint = endPoint + trimOffset
                if currentSeconds >= checkEndPoint {
                    self.player?.pause()
                    self.isPlaying = false
                    if let token = self.timeObserverToken {
                        self.player?.removeTimeObserver(token)
                        self.timeObserverToken = nil
                    }
                }
            }
        }

        /// 만약 재생이 트리밍 구간 내에서 멈춘 상태라면, 바로 이어서 재생
        if currentTimeSeconds >= actualStart, currentTimeSeconds < actualEnd {
            startPlaybackAndObserve()
        } else {
            /// 그렇지 않다면(처음 재생 또는 재생 완료 후), 시작점으로 이동 후 재생
            onSeek(startPoint)
            startPlaybackAndObserve()
        }
    }

    deinit {
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
        }
    }
}
