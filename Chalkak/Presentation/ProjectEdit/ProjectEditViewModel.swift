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
    private var project: Project?
    private var currentComposition: AVMutableComposition?
    private var timeObserverToken: Any?
    private var imageGenerator: AVAssetImageGenerator?
    
    @Published var editableClips: [EditableClip] = []
    @Published var isPlaying = false
    @Published var playHead: Double = 0
    @Published var player = AVPlayer()
    @Published var previewImage: UIImage? = nil
    @Published var isDragging = false
    @Published var guide: Guide? = nil
    
    var totalDuration: Double {
        editableClips.reduce(0) { $0 + $1.trimmedDuration }
    }
    
    // init
    init(projectID: String) {
        loadProject(of: projectID)
    }

    func loadProject(of projectID: String) {
        guard
            let project = SwiftDataManager.shared.fetchProject(byID: projectID)
        else {
            print("프로젝트를 찾을 수 없습니다.")
            return
        }
        
        self.project = project
        self.guide = project.guide
        
        // 확인했으니 isChecked처리
        SwiftDataManager.shared.markProjectAsChecked(projectID: projectID)

        let sorted = project.clipList.sorted { $0.createdAt < $1.createdAt }

        // 썸네일 미리 생성
        editableClips = sorted.map { clip in
            let thumbs = generateThumbnails(
                url: clip.videoURL,
                duration: clip.originalDuration,
                count: 10
            )
            return EditableClip(
                id: clip.id,
                url: clip.videoURL,
                originalDuration: clip.originalDuration,
                startPoint: clip.startPoint,
                endPoint: clip.endPoint,
                thumbnails: thumbs
            )
        }

        setupPlayer()
    }

    private func generateThumbnails(
        url: URL,
        duration: Double,
        count: Int
    ) -> [UIImage] {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        var imgs: [UIImage] = []
        let interval = duration / Double(count)
        for i in 0..<count {
            let time = CMTime(seconds: Double(i) * interval, preferredTimescale: 600)
            if let cg = try? generator.copyCGImage(at: time, actualTime: nil) {
                imgs.append(UIImage(cgImage: cg))
            }
        }
        return imgs
    }

    func setupPlayer() {
        let composition = AVMutableComposition()
        guard
            let vidTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ),
            let audTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            )
        else {
            return
        }

        var cursor = CMTime.zero
        for clip in editableClips {
            let asset = AVAsset(url: clip.url)
            let start = CMTime(seconds: clip.startPoint, preferredTimescale: 600)
            let dur   = CMTime(seconds: clip.trimmedDuration, preferredTimescale: 600)
            let range = CMTimeRange(start: start, duration: dur)

            if let track = asset.tracks(withMediaType: .video).first {
                try? vidTrack.insertTimeRange(range, of: track, at: cursor)
            }
            if let track = asset.tracks(withMediaType: .audio).first {
                try? audTrack.insertTimeRange(range, of: track, at: cursor)
            }
            cursor = cursor + dur
        }

        currentComposition = composition
        let previewComposition = composition.makePreviewVideoComposition(using: editableClips)
        let item = AVPlayerItem(asset: composition)
        item.videoComposition = previewComposition
        player.replaceCurrentItem(with: item)

        imageGenerator = AVAssetImageGenerator(asset: composition)
        imageGenerator?.appliesPreferredTrackTransform = true
        imageGenerator?.videoComposition = previewComposition

        Task { await updatePreviewImage(at: playHead) }

        if let token = timeObserverToken {
            player.removeTimeObserver(token)
        }
        addTimeObserver()
        addEndObserver()
    }

    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            guard let self = self else { return }
            let secs = CMTimeGetSeconds(time)
            
            DispatchQueue.main.async {
                self.playHead = secs
                
                Task { await self.updatePreviewImage(at: secs) }
                
                if let clip = self.editableClips.first(where: { $0.isTrimming }) {
                    let allStart = self.allClipStart(of: clip)
                    let allEnd = allStart + clip.trimmedDuration
                    if secs >= allEnd {
                        self.player.seek(
                            to: CMTime(seconds: allStart, preferredTimescale: 600),
                            toleranceBefore: .zero, toleranceAfter: .zero
                        )
                        // 계속 재생 중이라면, play() 호출 유지
                        if self.isPlaying {
                            self.player.play()
                        }
                    }
                } else {
                    if secs >= self.totalDuration {
                        self.isPlaying = false
                        self.player.pause()
                    }
                }
            }
        }
    }
    
    private func addEndObserver() {
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            // 재생이 끝나면 isPlaying false, 헤드 리셋
            self.isPlaying = false
            self.seekTo(time: 0)
        }
    }

    func updatePreviewImage(at time: Double) async {
        guard let gen = imageGenerator else { return }
        let cm = CMTime(seconds: time, preferredTimescale: 600)
        if let cg = try? gen.copyCGImage(at: cm, actualTime: nil) {
            await MainActor.run {
                self.previewImage = UIImage(cgImage: cg)
            }
        }
    }

    func togglePlayback() {
        if let clip = editableClips.first(where: { $0.isTrimming }) {
            let allStart = allClipStart(of: clip)
            let allEnd = allStart + clip.trimmedDuration
            
            if playHead < allStart || playHead >= allEnd {
                seekTo(time: allStart)
            }
            
            isPlaying.toggle()
            if isPlaying {
                player.play()
            } else {
                player.pause()
            }
            return
        }
        
        if playHead >= totalDuration {
            seekTo(time: 0)
        }
        
        isPlaying.toggle()
        if isPlaying { player.play() } else {
            player.pause()
        }
    }

    func seekTo(time: Double) {
        let cm = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cm, toleranceBefore: .zero, toleranceAfter: .zero)
        playHead = time
        Task {
            await updatePreviewImage(at: time)
        }
    }

    func toggleTrimmingMode(for clipID: String) {
        editableClips = editableClips.map { clip in
            var c = clip
            c.isTrimming = (c.id == clipID) ? !c.isTrimming : false
            return c
        }
    }

    func updateTrimRange(for clipID: String, start: Double, end: Double) {
        guard let idx = editableClips.firstIndex(where: { $0.id == clipID }) else { return }
        editableClips[idx].startPoint = max(0, min(start, editableClips[idx].originalDuration))
        editableClips[idx].endPoint   = max(0, min(end,   editableClips[idx].originalDuration))
        setupPlayer()
    }
    
    func deleteClip(id: String) {
        if let idx = editableClips.firstIndex(where: { $0.id == id }) {
            editableClips.remove(at: idx)
            setupPlayer()
        }
    }
    
    func allClipStart(of clip: EditableClip) -> Double {
      let idx = editableClips.firstIndex { $0.id == clip.id }!
      return editableClips[..<idx].reduce(0) { $0 + $1.trimmedDuration }
    }
    
    func setCurrentProjectID() {
        UserDefaults.standard.set(project?.id ?? nil, forKey: "currentProjectID")
    }
}
