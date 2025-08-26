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
    /// 프로젝트 로딩중
    @Published var isLoading = false

    // MARK: – 저장/내보내기용 프로퍼티

    @Published var isExporting = false
    private let videoManager = VideoManager()
    private let photoLibrarySaver = PhotoLibrarySaver()

    // 변경사항을 추적하기위한 originalClip - 상태 저장용 프로퍼티
    private var originalClips: [EditableClip] = []

    var totalDuration: Double {
        editableClips.reduce(0) { $0 + $1.trimmedDuration }
    }

    // 변경사항 감지
    var hasChanges: Bool {
        // 클립 개수에서 차이가날때
        if editableClips.count != originalClips.count {
            return true
        }

        // 각 클립의 trim 포인트가 다르면 변경된것으로판단
        for (edited, original) in zip(editableClips, originalClips) {
            if edited.id != original.id ||
                edited.startPoint != original.startPoint ||
                edited.endPoint != original.endPoint
            {
                return true
            }
        }

        return false
    }

    // init
    init(projectID: String) {
        self.projectID = projectID
    }

    // MARK: - 비동기 로딩 메서드

    func loadProjectAsync() async {
        isLoading = true

        // 백그라운드에서 프로젝트 로드
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.loadProjectData()
            }
        }

        isLoading = false
    }

    @MainActor
    private func loadProjectData() async {
        guard let project = SwiftDataManager.shared.fetchProject(byID: projectID) else {
            print("프로젝트를 찾을 수 없습니다.")
            return
        }

        self.project = project
        guide = project.guide

        // 확인했으니 isChecked처리
        SwiftDataManager.shared.markProjectAsChecked(projectID: projectID)

        let sorted = project.clipList.sorted { $0.createdAt < $1.createdAt }

        // 클립들을 먼저 기본 정보로 생성 (썸네일 없이)
        var tempClips: [EditableClip] = []

        for clip in sorted {
            // 비디오 파일 URL 검증 및 복구
            guard let validURL = FileManager.validVideoURL(from: clip.videoURL) else {
                print("클립 \(clip.id)의 비디오 파일을 찾을 수 없습니다: \(clip.videoURL)")
                continue
            }

            // URL이 변경되었다면 업데이트
            if validURL != clip.videoURL {
                print("클립 \(clip.id)의 URL을 업데이트합니다: \(clip.videoURL) -> \(validURL)")
                clip.videoURL = validURL
                SwiftDataManager.shared.saveContext()
            }

            // 빈 썸네일 배열로 초기화
            let editableClip = EditableClip(
                id: clip.id,
                url: validURL,
                originalDuration: clip.originalDuration,
                startPoint: clip.startPoint,
                endPoint: clip.endPoint,
                thumbnails: [] // 나중에 비동기로 생성
            )

            tempClips.append(editableClip)
        }

        // UI 업데이트 (썸네일 없이 먼저 표시)
        editableClips = tempClips

        // 원본 상태 저장 (변경사항 추적용)
        originalClips = tempClips

        // 플레이어 설정 (썸네일 없이도 가능)
        await setupPlayerAsync()

        // 썸네일을 백그라운드에서 비동기로 생성
        await generateThumbnailsAsync()
    }

    /// 비동기 썸네일 생성
    private func generateThumbnailsAsync() async {
        await withTaskGroup(of: (String, [UIImage]).self) { group in
            for clip in editableClips {
                group.addTask {
                    let thumbnails = await self.generateThumbnailsBackground(
                        url: clip.url,
                        duration: clip.originalDuration,
                        count: 10
                    )
                    return (clip.id, thumbnails)
                }
            }

            // 썸네일이 생성되는 대로 업데이트
            for await (clipID, thumbnails) in group {
                if let index = editableClips.firstIndex(where: { $0.id == clipID }) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        editableClips[index].thumbnails = thumbnails
                    }
                }
            }
        }
    }

    private func generateThumbnailsBackground(
        url: URL,
        duration: Double,
        count: Int
    ) async -> [UIImage] {
        return await withCheckedContinuation { continuation in
            Task.detached {
                // URL 유효성 검증
                guard FileManager.isValidVideoFile(at: url) else {
                    print("유효하지 않은 비디오 파일: \(url)")
                    continuation.resume(returning: [])
                    return
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
                    }
                }

                continuation.resume(returning: imgs)
            }
        }
    }

    /// 비동기 플레이어 설정
    @MainActor
    private func setupPlayerAsync() async {
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
                let vidTracks = try await asset.loadTracks(withMediaType: .video)
                guard !vidTracks.isEmpty else { continue }

                let audTracks = try await asset.loadTracks(withMediaType: .audio)
                guard !audTracks.isEmpty else { continue }

                if let track = vidTracks.first {
                    try vidTrack.insertTimeRange(range, of: track, at: cursor)
                }
                if let track = audTracks.first {
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

        await updatePreviewImage(at: playHead)

        if let token = timeObserverToken {
            player.removeTimeObserver(token)
        }
        addTimeObserver()
        addEndObserver()
    }

    // MARK: - 동기 메서드들

    func setupPlayer() {
        Task {
            await setupPlayerAsync()
        }
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
        // 트리밍 모드 토글
        editableClips = editableClips.map { clip in
            var c = clip
            c.isTrimming = (c.id == clipID) ? !c.isTrimming : false
            return c
        }
        
        // 트리밍 모드가 활성화된 클립을 찾고, 해당 클립의 시작 위치로 플레이헤드 이동
        if let trimmingClip = editableClips.first(where: { $0.isTrimming }) {
            // 해당 클립의 타임라인상 시작 위치
            let clipStartTime = allClipStart(of: trimmingClip)
            
            // 범위 체크
            let safeTime = min(max(0, clipStartTime), totalDuration)
            
            // 트리밍된 부분의 시작점으로 플레이헤드 이동
            seekTo(time: safeTime)
            
            // 재생 중이었다면 일시정지
            if isPlaying {
                isPlaying = false
                player.pause()
            }
        }
    }

    func deactivateAllTrimming() {
        for i in 0..<editableClips.count {
            editableClips[i].isTrimming = false
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

    func saveProjectChanges() async {
        // 프로젝트 엔티티 가져오기
        guard let project = SwiftDataManager.shared.fetchProject(byID: projectID) else {
            print("프로젝트(\(projectID))를 찾을 수 없습니다.")
            return
        }

        // 편집된 trim 값 반영
        for entity in project.clipList {
            if let edited = editableClips.first(where: { $0.id == entity.id }) {
                entity.startPoint = edited.startPoint
                entity.endPoint = edited.endPoint
            }
        }

        // 삭제된 클립 제거
        let removed = project.clipList.filter { entity in
            !editableClips.contains(where: { $0.id == entity.id })
        }
        removed.forEach { SwiftDataManager.shared.deleteClip($0) }

        // 저장
        SwiftDataManager.shared.saveContext()
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

    func setCurrentProjectID() {
        UserDefaults.standard.set(projectID, forKey: UserDefaultKey.currentProjectID)
    }
}
