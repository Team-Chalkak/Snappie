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
    @Published var editableClips: [EditableClip] = []
    @Published var isPlaying = false
    @Published var playHead: Double = 0
    @Published var player = AVPlayer()
    @Published var previewImage: UIImage? = nil
    @Published var isDragging = false

    private var currentComposition: AVMutableComposition?
    private var timeObserverToken: Any?
    private var imageGenerator: AVAssetImageGenerator?
    
    // MARK: - 프로젝트 로드
    func loadProject() {
        guard
            let projectID = UserDefaults.standard.string(forKey: "currentProjectID"),
            let project = SwiftDataManager.shared.fetchProject(byID: projectID)
        else { return }
        
        let sorted = project.clipList.sorted { $0.createdAt < $1.createdAt }
        editableClips = sorted.map { clip in
            EditableClip(
                id: clip.id,
                url: clip.videoURL,
                originalDuration: clip.originalDuration,
                startPoint: clip.startPoint,
                endPoint: clip.endPoint
            )
        }
        
        setupPlayer()
    }
    
    // MARK: - Composition 생성 & Player 세팅
    func setupPlayer() {
        let composition = AVMutableComposition()
        guard
            let vidTrack = composition.addMutableTrack(
                withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
            let audTrack = composition.addMutableTrack(
                withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        else {
            print("트랙 생성 실패")
            return
        }
        
        // 순차적으로 삽입
        var cursor = CMTime.zero
        for clip in editableClips {
            let asset = AVAsset(url: clip.url)
            let start = CMTime(seconds: clip.startPoint, preferredTimescale: 600)
            let dur   = CMTime(seconds: clip.trimmedDuration, preferredTimescale: 600)
            let range = CMTimeRange(start: start, duration: dur)
            
            if let t = asset.tracks(withMediaType: .video).first {
                try? vidTrack.insertTimeRange(range, of: t, at: cursor)
            }
            if let t = asset.tracks(withMediaType: .audio).first {
                try? audTrack.insertTimeRange(range, of: t, at: cursor)
            }
            cursor = cursor + dur
        }
        
        currentComposition = composition
        let item = AVPlayerItem(asset: composition)
        player.replaceCurrentItem(with: item)
        
        // ▶️ ImageGenerator 갱신
        imageGenerator = AVAssetImageGenerator(asset: composition)
        imageGenerator?.appliesPreferredTrackTransform = true
        
        // ▶️ 현재 프레임 즉시 뽑아오기
        Task { await updatePreviewImage(at: playHead) }
        
        // ▶️ 시간 옵저버 재등록
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
        }
        addTimeObserver()
    }
    
    // MARK: - 시간 옵저빙 & Preview 업데이트
    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let seconds = CMTimeGetSeconds(time)
            self.playHead = seconds
            
            // ▶️ 프리뷰 이미지 업데이트
            Task { await self.updatePreviewImage(at: seconds) }
            
            // ▶️ 끝나면 자동 정지
            if seconds >= self.totalDuration {
                self.isPlaying = false
                self.player.pause()
            }
        }
    }
    
    func updatePreviewImage(at time: Double) async {
        guard let gen = imageGenerator else { return }
        let cm = CMTime(seconds: time, preferredTimescale: 600)
        if let cg = try? gen.copyCGImage(at: cm, actualTime: nil) {
            self.previewImage = UIImage(cgImage: cg)
        }
    }
    
    // MARK: - 제어 액션
    func togglePlayback() {
        isPlaying.toggle()
        isPlaying ? player.play() : player.pause()
    }
    
    func seekTo(time: Double) {
        let cm = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cm, toleranceBefore: .zero, toleranceAfter: .zero)
        playHead = time
    }
    
    /// 단일 클립만 트리밍 모드 on/off
    func toggleTrimmingMode(for clipID: String) {
        editableClips = editableClips.map { clip in
            var c = clip
            c.isTrimming = (clip.id == clipID) ? !clip.isTrimming : false
            return c
        }
    }
    
    /// 트리밍 범위 갱신 → Composition 재생성
    func updateTrimRange(for clipID: String, start: Double, end: Double) {
        guard let idx = editableClips.firstIndex(where: { $0.id == clipID }) else { return }
        editableClips[idx].startPoint = max(0, min(start, editableClips[idx].originalDuration))
        editableClips[idx].endPoint   = max(0, min(end,   editableClips[idx].originalDuration))
        setupPlayer()
    }
    
    /// 전체 길이
    var totalDuration: Double {
        editableClips.reduce(0) { $0 + $1.trimmedDuration }
    }
}
