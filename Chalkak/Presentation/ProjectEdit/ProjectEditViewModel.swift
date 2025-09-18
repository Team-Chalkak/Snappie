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
    private var projectID: String
    private var currentComposition: AVMutableComposition?
    private var timeObserverToken: Any?
    private var isTimeObserverActive = true
    private var imageGenerator: AVAssetImageGenerator?
    
    @Published var editableClips: [EditableClip] = []
    @Published var isPlaying = false
    @Published var playHead: Double = 0
    @Published var player = AVPlayer()
    @Published var previewImage: UIImage? = nil
    @Published var isDragging = false
    @Published var guide: Guide? = nil /// 프로젝트 로딩중
    @Published var isLoading = false
    @Published var showEmptyProjectAlert = false
    
    // MARK: – 저장/내보내기용 프로퍼티

    @Published var isExporting = false
    private let videoManager = VideoManager()
    private let photoLibrarySaver = PhotoLibrarySaver()

    // 변경사항을 추적하기위한 originalClip - 상태 저장용 프로퍼티
    private var originalClips: [EditableClip] = []

    var totalDuration: Double {
        editableClips.reduce(0) { $0 + $1.trimmedDuration }
    }
    
    // MARK: - Temp 관련 프로퍼티

    var hasChanges: Bool {
        guard let project = SwiftDataManager.shared.fetchProject(byID: projectID) else { return false }
        return project.isTemp
    }
    
    var originalProjectID: String {
        guard let project = SwiftDataManager.shared.fetchProject(byID: projectID),
              project.isTemp,
              let originalID = project.originalID
        else {
            return projectID
        }
        return originalID
    }
    
    // init
    init(projectID: String) {
        self.projectID = projectID
    }

    // MARK: - 비동기 로딩 메서드

    /// 메인 프로젝트 로딩 메서드
    func loadProject() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let project = SwiftDataManager.shared.fetchProject(byID: projectID) else {
            print("프로젝트를 찾을 수 없습니다.")
            return
        }
        
        // 기본 프로젝트 정보 설정
        await setupBasicProjectInfo(project)
        
        // 클립 로딩과 UI 설정
        await loadClipsAndSetupUI(from: project)
    }
    
    /// 기본 프로젝트 정보 설정
    private func setupBasicProjectInfo(_ project: Project) async {
        await MainActor.run {
            self.project = project
            self.guide = project.guide
        }
        
        // 확인 처리 (temp가 아닌 경우만)
        if !project.isTemp {
            SwiftDataManager.shared.markProjectAsChecked(projectID: projectID)
        }
    }
    
    /// 클립 로딩과 UI 설정
    private func loadClipsAndSetupUI(from project: Project) async {
        let orderedClips = orderedClips(from: project)
        
        // 1단계: 기본 클립 정보로 UI 먼저 업데이트
        let basicClips = await createValidatedEditableClips(from: orderedClips)
        
        await MainActor.run {
            self.editableClips = basicClips
            self.originalClips = basicClips
        }
        
        // 2단계: 플레이어 설정
        await setupPlayerAsync()
        
        // 3단계: 썸네일을 순차적으로 생성
        await generateThumbnailsSequentially()
    }
    
    /// URL 검증과 EditableClip 생성
    private func createValidatedEditableClips(from clips: [Clip]) async -> [EditableClip] {
        var validClips: [EditableClip] = []
        
        for clip in clips {
            if let validatedClip = await validateAndCreateEditableClip(from: clip) {
                validClips.append(validatedClip)
            }
        }
        
        return validClips
    }
    
    /// 개별 클립 검증 및 생성
    private func validateAndCreateEditableClip(from clip: Clip) async -> EditableClip? {
        guard let validURL = FileManager.validVideoURL(from: clip.videoURL) else {
            print("클립 \(clip.id)의 비디오 파일을 찾을 수 없습니다: \(clip.videoURL)")
            return nil
        }
        
        // URL 업데이트가 필요한 경우
        if validURL != clip.videoURL {
            print("클립 \(clip.id)의 URL을 업데이트합니다")
            await MainActor.run {
                clip.videoURL = validURL
                SwiftDataManager.shared.saveContext()
            }
        }
        
        return EditableClip(
            id: clip.id,
            url: validURL,
            originalDuration: clip.originalDuration,
            startPoint: clip.startPoint,
            endPoint: clip.endPoint,
            thumbnails: []
        )
    }
    
    /// 메모리 효율적인 순차 썸네일 생성
    private func generateThumbnailsSequentially() async {
        for (index, clip) in editableClips.enumerated() {
            let thumbnails = await generateThumbnailsBackground(
                url: clip.url,
                duration: clip.originalDuration,
                count: 10
            )
            
            // 안전한 UI 업데이트
            await MainActor.run {
                guard index < self.editableClips.count,
                      self.editableClips[index].id == clip.id else {
                    print("클립 배열이 변경되어 썸네일 업데이트를 건너뜁니다.")
                    return
                }
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.editableClips[index].thumbnails = thumbnails
                }
            }
            
            // UI 응답성을 위한 짧은 대기
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
    }

    private func generateThumbnailsBackground(
        url: URL,
        duration: Double,
        count: Int
    ) async -> [UIImage] {
        return await withCheckedContinuation { continuation in
            Task.detached {
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
        let savedPlayHead = playHead
        
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
        
        // 저장된 플레이헤드 위치로 복원
        if savedPlayHead > 0, savedPlayHead <= totalDuration {
            await updatePreviewImage(at: savedPlayHead)
        } else {
            await updatePreviewImage(at: playHead)
        }
        
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
        // 상태가 활성화되어 있을 때만 새로운 옵저버 생성
        if isTimeObserverActive {
            addTimeObserver()
        }
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
            
            // 드래그 중이면 아무것도 안 함
            guard !self.isDragging else { return }
            
            let secs = CMTimeGetSeconds(time)
            DispatchQueue.main.async {
                self.playHead = secs
                Task { await self.updatePreviewImage(at: secs) }
                
                // 기존 트리밍 로직도 그대로 유지
                if let clip = self.editableClips.first(where: { $0.isTrimming }) {
                    let allStart = self.allClipStart(of: clip)
                    let allEnd = allStart + clip.trimmedDuration
                    if secs >= allEnd {
                        self.player.seek(
                            to: CMTime(seconds: allStart, preferredTimescale: 600),
                            toleranceBefore: .zero, toleranceAfter: .zero
                        )
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
    
    private func pauseTimeObserver() {
        isTimeObserverActive = false
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }

    private func resumeTimeObserver() {
        guard !isTimeObserverActive else { return } // 이미 활성화된 경우 중복 방지
        isTimeObserverActive = true
        addTimeObserver() // 새로운 옵저버 추가
    }
    
    func setDraggingState(_ dragging: Bool) {
        isDragging = dragging
        
        // 드래그 시작시: 재생 중이면 일시정지하고 timeObserver 정지
        if dragging {
            if isPlaying {
                player.pause()
                isPlaying = false
            }
            pauseTimeObserver()
        }
        // 드래그 완료시: timeObserver 재시작하고 플레이어 업데이트
        else {
            Task {
                // 현재 플레이헤드 위치를 저장
                let currentTime = self.playHead
                
                self.resumeTimeObserver()
                await self.setupPlayerAsync()
                
                // 저장된 위치로 복원 (0초가 아님)
                if currentTime > 0 && currentTime <= self.totalDuration {
                    self.seekTo(time: currentTime)
                }
            }
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
        
        // 끝에 도달했을 때 0초로 리셋하지 않고 그 자리에서 정지
        if playHead >= totalDuration {
            isPlaying = false
            player.pause()
            return
        }
        
        isPlaying.toggle()
        if isPlaying {
            player.play()
        } else {
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
        for i in 0 ..< editableClips.count {
            editableClips[i].isTrimming = false
        }
    }

    func allClipStart(of clip: EditableClip) -> Double {
        guard let idx = editableClips.firstIndex(where: { $0.id == clip.id }) else {
            return 0
        }
        return editableClips[..<idx].reduce(0) { $0 + $1.trimmedDuration }
    }

    func moveClip(from source: IndexSet, to destination: Int) {
        let currentTime = playHead
        
        // 1. Reorder the UI-facing array
        editableClips.move(fromOffsets: source, toOffset: destination)

        // 2. Persist the new order in the temporary SwiftData project
        writeOrdersToTempProjectAndNormalize()

        // 3. After reordering, the player composition is invalid. Rebuild it.
        Task {
            await setupPlayerAsync()
            
            // 이동 후에도 원래 위치 유지
            if currentTime > 0 && currentTime <= self.totalDuration {
                self.seekTo(time: currentTime)
            }
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

    func setCurrentProjectID() {
        UserDefaults.standard.set(projectID, forKey: UserDefaultKey.currentProjectID)
    }
    
    // MARK: - 빈 프로젝트(클립이 모두 삭제된 프로젝트) 삭제

    func deleteEmptyProject() async -> Bool {
        // 1. temp 정리 (discardChanges와 동일)
        guard let tempProject = SwiftDataManager.shared.fetchProject(byID: projectID),
              tempProject.isTemp,
              let originalID = tempProject.originalID
        else {
            return false
        }
        
        // 2. temp 프로젝트만 삭제 (원본은 그대로)
        SwiftDataManager.shared.deleteTempProject(tempProject)
        
        // 3. 원본 프로젝트 ID 저장 (삭제 대상으로)
        UserDefaults.standard.set(originalID, forKey: "ProjectToDelete")
        
        return true
    }
    
    // MARK: - Temp System 메서드들

    /// temp 프로젝트 초기화 (ProjectEditView 진입 시 호출)
    func initializeTempProject(loadAfter: Bool = true) async {
        guard let originalProject = SwiftDataManager.shared.fetchProject(byID: projectID) else {
            print("원본 프로젝트를 찾을 수 없습니다.")
            return
        }
        
        // 이미 temp면 그대로 로드
        if originalProject.isTemp {
            if loadAfter {
                await loadProject()
            }
            return
        }
        
        // temp 프로젝트 생성
        let tempID = await createTempProject(from: originalProject)
        
        // ViewModel을 temp로 전환
        projectID = tempID
        project = SwiftDataManager.shared.fetchProject(byID: tempID)
        
        if loadAfter {
            await loadProject()
        }
    }
    
    /// temp 프로젝트 생성 메서드
     private func createTempProject(from originalProject: Project) async -> String {
         let tempID = "temp_\(UUID().uuidString)"
         
         // 기본 객체들 생성
         let tempGuide = createTempGuide(from: originalProject.guide)
         let tempCameraSetting = createTempCameraSetting(from: originalProject.cameraSetting)
         
         // temp 프로젝트 생성
         let tempProject = Project(
             id: tempID,
             guide: tempGuide,
             clipList: [],
             cameraSetting: tempCameraSetting,
             title: originalProject.title,
             referenceDuration: originalProject.referenceDuration,
             isChecked: originalProject.isChecked,
             coverImage: originalProject.coverImage,
             createdAt: originalProject.createdAt,
             isTemp: true,
             originalID: projectID
         )
         
         // 클립들을 temp로 복사
         let tempClips = createTempClips(from: originalProject.clipList)
         tempProject.clipList = tempClips
         
         // Context에 추가
         addToContext(tempGuide, tempCameraSetting, tempProject)
         
         return tempID
     }
    
    /// Guide 복사
    private func createTempGuide(from originalGuide: Guide) -> Guide {
        return Guide(
            clipID: "temp_\(originalGuide.clipID)",
            boundingBoxes: originalGuide.boundingBoxes,
            outlineImage: originalGuide.outlineImage ?? UIImage(),
            cameraTilt: originalGuide.cameraTilt
        )
    }

    /// CameraSetting 복사
    private func createTempCameraSetting(from originalSetting: CameraSetting?) -> CameraSetting? {
        guard let originalSetting = originalSetting else { return nil }
        
        return CameraSetting(
            zoomScale: originalSetting.zoomScale,
            isGridEnabled: originalSetting.isGridEnabled,
            isFrontPosition: originalSetting.isFrontPosition,
            timerSecond: originalSetting.timerSecond
        )
    }
    
    /// 클립 복사
    private func createTempClips(from originalClips: [Clip]) -> [Clip] {
        let orderedOriginalClips = originalClips.sorted {
            if $0.order != $1.order { return $0.order < $1.order }
            return $0.createdAt < $1.createdAt
        }
        
        return orderedOriginalClips.enumerated().map { (index, originalClip) in
            let tempClip = Clip(
                id: "temp_\(UUID().uuidString)",
                videoURL: originalClip.videoURL,
                originalDuration: originalClip.originalDuration,
                startPoint: originalClip.startPoint,
                endPoint: originalClip.endPoint,
                createdAt: originalClip.createdAt,
                tiltList: originalClip.tiltList,
                isTemp: true,
                originalClipID: originalClip.id
            )
            tempClip.order = index
            return tempClip
        }
    }
    
    /// Context 추가
    private func addToContext(_ guide: Guide, _ cameraSetting: CameraSetting?, _ project: Project) {
        SwiftDataManager.shared.context.insert(guide)
        
        if let cameraSetting = cameraSetting {
            SwiftDataManager.shared.context.insert(cameraSetting)
        }
        
        SwiftDataManager.shared.context.insert(project)
        SwiftDataManager.shared.saveContext()
    }
    
    /// temp에 클립 추가
    func addClipToTemp(clip: Clip) {
        guard let tempProject = SwiftDataManager.shared.fetchProject(byID: projectID),
              tempProject.isTemp
        else {
            print("현재 temp 프로젝트가 아닙니다.")
            return
        }
        
        configureClipAsTemp(clip, for: tempProject)
        
        Task {
            await loadProject()
        }
    }

    /// 클립을 temp로 설정
    private func configureClipAsTemp(_ clip: Clip, for tempProject: Project) {
        let nextOrder = (tempProject.clipList.map(\.order).max() ?? -1) + 1
        
        clip.isTemp = true
        clip.originalClipID = nil
        clip.order = nextOrder
        
        tempProject.clipList.append(clip)
        SwiftDataManager.shared.saveContext()
    }

    /// 클립 삭제 (temp에서만 안전하게 삭제)
    func deleteClip(id: String) {
        print("클립 삭제 시작: \(id)")
        
        guard let tempProject = SwiftDataManager.shared.fetchProject(byID: projectID),
              tempProject.isTemp
        else {
            print("경고: temp 프로젝트가 아닌 상태에서 deleteClip 호출됨")
            return
        }
        
        // 마지막 클립인지 확인 - 삭제 전에 미리 체크
        if tempProject.clipList.count == 1 {
            // 해당 클립이 삭제하려는 클립인지 확인
            if tempProject.clipList.first?.id == id {
                showEmptyProjectAlert = true
                return // 여기서 완전히 종료, 아무것도 삭제하지 않음
            }
        }
        let currentTime = playHead

        // 1. 플레이어 정리 (삭제될 클립 참조 방지)
        player.pause()
        isPlaying = false
        player.replaceCurrentItem(with: nil)
        
        // 2. UI에서 제거
        editableClips.removeAll { $0.id == id }
        
        // 3. temp 프로젝트에서 클립 제거 (cascade가 자동으로 SwiftData 삭제 처리)
        if let _ = tempProject.clipList.first(where: { $0.id == id }) {
            tempProject.clipList.removeAll { $0.id == id }
            // cascade로 인해 clipToDelete는 자동으로 삭제됨
            
            // order 재정렬
            for (idx, c) in tempProject.clipList.enumerated() {
                c.order = idx
            }
            SwiftDataManager.shared.saveContext()
            print("클립 삭제 완료")
        }
        
        // 4. 플레이어 재설정
        Task {
            await setupPlayerAsync()
            
            // 삭제 후에도 적절한 위치로 복원
            let newTotalDuration = self.totalDuration
            if currentTime > 0 && currentTime <= newTotalDuration {
                self.seekTo(time: min(currentTime, newTotalDuration))
            } else if newTotalDuration > 0 {
                // 현재 위치가 새로운 총 길이를 초과하면 끝으로 이동 (0이 아님)
                self.seekTo(time: newTotalDuration)
            }
        }
    }
    
    /// 트리밍 범위 업데이트 (temp에만 반영)
    func updateTrimRange(for clipID: String, start: Double, end: Double) {
        // UI 업데이트
        guard let idx = editableClips.firstIndex(where: { $0.id == clipID }) else { return }
        editableClips[idx].startPoint = max(0, min(start, editableClips[idx].originalDuration))
        editableClips[idx].endPoint = max(0, min(end, editableClips[idx].originalDuration))
        
        // 드래그 중이 아닐 때 플레이어 업데이트 수행
        if !isDragging {
            setupPlayer()
        }
        
        // temp 프로젝트의 clip도 업데이트
        if let tempProject = SwiftDataManager.shared.fetchProject(byID: projectID),
           tempProject.isTemp,
           let tempClip = tempProject.clipList.first(where: { $0.id == clipID })
        {
            tempClip.startPoint = editableClips[idx].startPoint
            tempClip.endPoint = editableClips[idx].endPoint
            SwiftDataManager.shared.saveContext()
        }
    }
    
    /// 변경사항 저장 (temp → 원본으로 머지)
    func commitChanges() async -> Bool {
        guard let tempProject = SwiftDataManager.shared.fetchProject(byID: projectID),
              tempProject.isTemp,
              let originalID = tempProject.originalID,
              let originalProject = SwiftDataManager.shared.fetchProject(byID: originalID)
        else {
            // temp가 아니면 이미 저장된 상태
            return true
        }
        
        // 1. 클립 변경사항 머지
        mergeClipChanges(from: tempProject, to: originalProject)
        
        // 2. 프로젝트 메타데이터 반영
        originalProject.title = tempProject.title
        originalProject.referenceDuration = tempProject.referenceDuration
        originalProject.coverImage = tempProject.coverImage
        
        // 3. temp 프로젝트 삭제 전 완전히 분리
        SwiftDataManager.shared.deleteTempProject(tempProject)
        
        // 4. ViewModel을 원본으로 복원
        projectID = originalID
        project = originalProject
        
        return true
    }
    
    /// 변경사항 취소 (temp 삭제로 롤백)
    func discardChanges() async -> Bool {
        guard let tempProject = SwiftDataManager.shared.fetchProject(byID: projectID),
              tempProject.isTemp,
              let originalID = tempProject.originalID
        else {
            // temp가 아니면 취소할 것 없음
            return true
        }
        
        // temp 프로젝트만 삭제 (원본은 자동 복구)
        SwiftDataManager.shared.deleteTempProject(tempProject)
        
        // ViewModel을 원본으로 복원
        projectID = originalID
        project = SwiftDataManager.shared.fetchProject(byID: originalID)
        
        return true
    }
    
    /// temp → 원본으로 클립 변경사항 머지
    private func mergeClipChanges(from tempProject: Project, to originalProject: Project) {
        let tempOrdered = tempProject.clipList.sorted {
            if $0.order != $1.order { return $0.order < $1.order }
            return $0.createdAt < $1.createdAt
        }
        let originalClips = originalProject.clipList

        // 삭제 반영
        let deleted = originalClips.filter { orig in
            !tempOrdered.contains { $0.originalClipID == orig.id }
        }
        for d in deleted {
            originalProject.clipList.removeAll { $0.id == d.id }
        }

        // 새 순서로 재구성 + order 부여
        var newClipOrder: [Clip] = []
        for (idx, t) in tempOrdered.enumerated() {
            if let oid = t.originalClipID,
               let orig = originalClips.first(where: { $0.id == oid })
            {
                orig.startPoint = t.startPoint
                orig.endPoint = t.endPoint
                orig.tiltList = t.tiltList
                orig.videoURL = t.videoURL
                orig.originalDuration = t.originalDuration
                orig.order = idx
                newClipOrder.append(orig)
            } else {
                let newClip = Clip(
                    id: UUID().uuidString,
                    videoURL: t.videoURL,
                    originalDuration: t.originalDuration,
                    startPoint: t.startPoint,
                    endPoint: t.endPoint,
                    createdAt: t.createdAt,
                    tiltList: t.tiltList,
                    isTemp: false,
                    originalClipID: nil
                )
                newClip.order = idx
                SwiftDataManager.shared.context.insert(newClip)
                newClipOrder.append(newClip)
            }
        }

        originalProject.clipList = newClipOrder
        SwiftDataManager.shared.saveContext()
    }
    
    // 현재 UI 순서를 id -> index 맵으로 만든다.
    private func uiIndexMap() -> [String: Int] {
        Dictionary(uniqueKeysWithValues: editableClips.enumerated().map { ($1.id, $0) })
    }

    // 저장소(Project)의 clipList를 UI 순서대로 반영하고, 0...N-1로 normalize한다.
    private func writeOrdersToTempProjectAndNormalize() {
        guard let tempProject = SwiftDataManager.shared.fetchProject(byID: projectID),
              tempProject.isTemp else { return }

        let indexMap = uiIndexMap()

        // 1) 각 클립의 order를 UI 인덱스로 기록 (UI에 없는 id는 맨 끝으로)
        for clip in tempProject.clipList {
            clip.order = indexMap[clip.id] ?? Int.max
        }

        // 2) 메모리 배열도 order로 정렬
        tempProject.clipList.sort {
            if $0.order != $1.order { return $0.order < $1.order }
            return $0.createdAt < $1.createdAt
        }

        // 3) 0...N-1로 재부여(정규화) – 중복/빈틈 제거
        for (idx, c) in tempProject.clipList.enumerated() {
            c.order = idx
        }

        SwiftDataManager.shared.saveContext()
    }

    // 로딩 시 클립 배열을 order 기준으로 안정 정렬 + 이상하면 자동 복구
    private func orderedClips(from project: Project) -> [Clip] {
        var arr = project.clipList.sorted {
            if $0.order != $1.order { return $0.order < $1.order }
            return $0.createdAt < $1.createdAt
        }
        // order가 비었거나 중복/불연속이면 0...N-1로 보정
        let shouldFix = Set(arr.map(\.order)).count != arr.count
            || (arr.first?.order ?? 0) != 0
            || (arr.last?.order ?? -1) != arr.count - 1
        if shouldFix {
            for (i, c) in arr.enumerated() {
                c.order = i
            }
            SwiftDataManager.shared.saveContext()
        }
        return arr
    }
}
