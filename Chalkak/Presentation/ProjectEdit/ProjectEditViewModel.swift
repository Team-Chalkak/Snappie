//
//  ProjectEditViewModel.swift
//  Chalkak
//
//  Created by 배현진 on 7/24/25.
//

import AVFoundation
import Foundation
import SwiftUI

@MainActor
final class ProjectEditViewModel: ObservableObject {
    private var project: Project?
    private let projectID: String
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

    // MARK: – 저장/내보내기용 프로퍼티
    @Published var isExporting = false
    private let videoManager = VideoManager()
    private let photoLibrarySaver = PhotoLibrarySaver()

    var totalDuration: Double {
        editableClips.reduce(0) { $0 + $1.trimmedDuration }
    }

    // init
    init(projectID: String) {
        self.projectID = projectID
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
        guide = project.guide

        // 확인했으니 isChecked처리
        SwiftDataManager.shared.markProjectAsChecked(projectID: projectID)

        let sorted = project.clipList.sorted { $0.createdAt < $1.createdAt }

        editableClips = sorted.compactMap { clip in
            // 비디오 파일 URL 검증 및 복구
            guard let validURL = FileManager.validVideoURL(from: clip.videoURL) else {
                print("클립 \(clip.id)의 비디오 파일을 찾을 수 없습니다: \(clip.videoURL)")
                return nil
            }

            // URL이 변경되었다면 업데이트
            if validURL != clip.videoURL {
                print("클립 \(clip.id)의 URL을 업데이트합니다: \(clip.videoURL) -> \(validURL)")
                clip.videoURL = validURL
                SwiftDataManager.shared.saveContext()
            }

            let thumbs = generateThumbnails(
                url: validURL,
                duration: clip.originalDuration,
                count: 10
            )
            return EditableClip(
                id: clip.id,
                url: validURL,
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
        // URL 유효성 검증
        guard FileManager.isValidVideoFile(at: url) else {
            print("유효하지 않은 비디오 파일: \(url)")
            return []
        }

        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        var imgs: [UIImage] = []
        let interval = duration / Double(count)
        for i in 0 ..< count {
            let time = CMTime(seconds: Double(i) * interval, preferredTimescale: 600)
            do {
                let cg = try generator.copyCGImage(at: time, actualTime: nil)
                imgs.append(UIImage(cgImage: cg))
            } catch {
                print("썸네일 생성 실패 at \(time.seconds)s: \(error)")
                // 실패한 경우 빈 이미지나 기본 이미지를 추가하지 않고 건너뜀
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
            // URL 유효성 재확인
            guard FileManager.isValidVideoFile(at: clip.url) else {
                print("setupPlayer: 유효하지 않은 비디오 파일 건너뛰기: \(clip.url)")
                continue
            }

            let asset = AVAsset(url: clip.url)
            let start = CMTime(seconds: clip.startPoint, preferredTimescale: 600)
            let dur = CMTime(seconds: clip.trimmedDuration, preferredTimescale: 600)
            let range = CMTimeRange(start: start, duration: dur)

            do {
                if let track = asset.tracks(withMediaType: .video).first {
                    try vidTrack.insertTimeRange(range, of: track, at: cursor)
                }
                if let track = asset.tracks(withMediaType: .audio).first {
                    try audTrack.insertTimeRange(range, of: track, at: cursor)
                }
                cursor = cursor + dur
            } catch {
                print("트랙 삽입 실패 for clip \(clip.id): \(error)")
                // 실패한 클립은 건너뛰고 계속 진행
            }
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
        editableClips[idx].endPoint = max(0, min(end, editableClips[idx].originalDuration))
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
    
    // MARK: – 프로젝트 변경사항 저장
    func saveProjectChanges() {
        // 프로젝트 엔티티 가져오기
        guard let project = SwiftDataManager.shared.fetchProject(byID: projectID) else {
            print("프로젝트(\(projectID))를 찾을 수 없습니다.")
            return
        }

        // 편집된 trim 값 반영
        for entity in project.clipList {
            if let edited = editableClips.first(where: { $0.id == entity.id }) {
                entity.startPoint = edited.startPoint
                entity.endPoint   = edited.endPoint
            }
        }

        // 삭제된 클립 제거
        let removed = project.clipList.filter { entity in
            !editableClips.contains(where: { $0.id == entity.id })
        }
        removed.forEach { SwiftDataManager.shared.deleteClip($0) }

        // 저장
        do {
            try SwiftDataManager.shared.saveContext()
            print("편집 내용 저장 완료")
        } catch {
            print("저장 실패:", error)
        }
    }
    
    // MARK: – 편집된 영상 갤러리에 내보내기
    func exportEditedVideoToPhotos() async {
        isExporting = true
        defer { isExporting = false }

        do {
            // videoManager는 processAndSaveVideo(clips:)를 구현해 두세요.
            // 클립 배열을 받아 합쳐진 URL을 리턴하도록 만듭니다.
            let finalURL = try await videoManager.processAndSaveVideo(clips: editableClips)
            await photoLibrarySaver.saveVideoToLibrary(videoURL: finalURL)
            print("내보내기 완료:", finalURL)
        } catch {
            print("내보내기 실패:", error)
        }
    }
}
