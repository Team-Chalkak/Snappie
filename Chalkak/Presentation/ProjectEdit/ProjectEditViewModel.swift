//
//  ProjectEditViewModel.swift
//  Chalkak
//
//  Created by 배현진 on 7/24/25.
//

import Foundation
import AVFoundation
import SwiftUI

@MainActor
final class ProjectEditViewModel: ObservableObject {
    
    // MARK: - Published 상태
    
    @Published var editableClips: [EditableClip] = []
    @Published var isPlaying: Bool = false
    @Published var playHead: Double = 0
    @Published var player: AVPlayer = AVPlayer()
    @Published var previewImage: UIImage? = nil
    @Published var isDragging: Bool = false
    private var imageGenerator: AVAssetImageGenerator?
    
    // MARK: - 내부 상태
    private var currentComposition: AVMutableComposition?
    private var timeObserverToken: Any?
    
    // MARK: - 로직

    /// 프로젝트 로드 및 클립 초기화
    func loadProject() {
        guard let projectID = UserDefaults.standard.string(forKey: "currentProjectID"),
              let project = SwiftDataManager.shared.fetchProject(byID: projectID) else {
            print("프로젝트를 찾을 수 없습니다.")
            return
        }

        let sortedClips = project.clipList.sorted { $0.createdAt < $1.createdAt }

        self.editableClips = sortedClips.map { EditableClip(from: $0) }

        setupPlayer()
    }

    /// AVComposition 생성 및 Player 세팅
    func setupPlayer() {
            // 새로운 Composition
            let composition = AVMutableComposition()
            guard
                let compVideoTrack = composition.addMutableTrack(
                    withMediaType: .video,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                ),
                let compAudioTrack = composition.addMutableTrack(
                    withMediaType: .audio,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                )
            else {
                print("트랙 생성에 실패했습니다.")
                return
            }

            // 순서대로 클립 삽입
            var cursor = CMTime.zero
            for clip in editableClips {
                let asset = AVAsset(url: clip.url)
                let start = CMTime(seconds: clip.startPoint, preferredTimescale: 600)
                let duration = CMTime(seconds: clip.duration, preferredTimescale: 600)
                let timeRange = CMTimeRange(start: start, duration: duration)

                do {
                    // 비디오
                    if let videoAssetTrack = asset.tracks(withMediaType: .video).first {
                        try compVideoTrack.insertTimeRange(
                            timeRange,
                            of: videoAssetTrack,
                            at: cursor
                        )
                    } else {
                        print("\(clip.id) 비디오 트랙이 없습니다.")
                    }

                    // 오디오
                    if let audioAssetTrack = asset.tracks(withMediaType: .audio).first {
                        try compAudioTrack.insertTimeRange(
                            timeRange,
                            of: audioAssetTrack,
                            at: cursor
                        )
                    }

                    cursor = CMTimeAdd(cursor, duration)
                } catch {
                    print("클립 삽입 중 에러 (\(clip.id)): \(error)")
                }
            }

            // AVPlayerItem 교체
            currentComposition = composition
            let playerItem = AVPlayerItem(asset: composition)
            player.replaceCurrentItem(with: playerItem)

            // timeObserver 재등록
            if let token = timeObserverToken {
                player.removeTimeObserver(token)
            }
            addTimeObserver()
        }

    /// AVPlayer 재생 시간 감지
    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let seconds = CMTimeGetSeconds(time)
            self.playHead = seconds
            
            if seconds >= self.totalDuration {
                self.isPlaying = false
                self.player.pause()
            }
            
            Task {
                await self.updatePreviewImage(at: seconds)
            }
        }
    }

    /// 재생 위치 이동
    func seekTo(time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        playHead = time
    }

    /// 재생/정지 토글
    func togglePlayback() {
        isPlaying.toggle()
        isPlaying ? player.play() : player.pause()
    }

    /// 트리밍 모드 ON/OFF
    func toggleTrimmingMode(for clipID: String) {
        guard let index = editableClips.firstIndex(where: { $0.id == clipID }) else { return }
        editableClips[index].isTrimming.toggle()
    }

    /// 트리밍 범위 갱신
    func updateTrimRange(for clipID: String, start: Double, end: Double) {
        guard let index = editableClips.firstIndex(where: { $0.id == clipID }) else { return }

        editableClips[index].startPoint = max(0, min(start, editableClips[index].originalDuration))
        editableClips[index].endPoint = max(0, min(end, editableClips[index].originalDuration))

        /// 트리밍 반영되었으므로 Composition 다시 생성
        setupPlayer()
    }

    /// 전체 영상 길이 계산
    var totalDuration: Double {
        editableClips.reduce(0) { $0 + $1.duration }
    }
    
    func updatePreviewImage(at time: Double) async {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        do {
            if let cgImage = try imageGenerator?.copyCGImage(at: cmTime, actualTime: nil) {
                self.previewImage = UIImage(cgImage: cgImage)
            }
        } catch {
            print("preview image 생성 실패: \(error)")
        }
    }
}
