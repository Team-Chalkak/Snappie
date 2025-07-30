//
//  ClipEditViewModel.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

import AVFoundation
import Foundation
import SwiftData
import UIKit

/**
 ClipEditViewModel: 클립 편집 뷰모델

 영상 클립의 재생, 트리밍 범위 설정, 썸네일 생성, 프리뷰 이미지 갱신, 클립 및 프로젝트 저장 등의 기능을 담당하는 ViewModel

 ## 주요 기능
 - AVPlayer 및 AVAssetImageGenerator 초기화
 - 트리밍 타임라인 썸네일 이미지 생성
 - 트리밍 시작/종료 지점 관리 및 프리뷰 이미지 갱신
 - Clip 모델 저장 및 Project 생성 또는 클립 추가

 ## 데이터 흐름
 1. ClipEditView 진입 시, clipURL을 받아 초기화
    └ asset 구성 및 썸네일, duration, player 설정

 2. TrimmingLineView에서 핸들 드래그
    └ updateStart / updateEnd(좌우 트리밍 핸들 위치) 호출 → previewImage 변경

 3. "다음" 버튼 클릭
    ├─ guide == nil : saveProjectData() 호출 → Clip 및 Project 생성
    └─ guide != nil : appendClipToCurrentProject() 호출 → 기존 Project에 Clip 추가
 */
final class ClipEditViewModel: ObservableObject {
    // 1. Input
    var clipURL: URL
    var cameraSetting: CameraSetting
    var timeStampedTiltList: [TimeStampedTilt]

    // 2. Published properties
    @Published var player: AVPlayer?
    @Published var startPoint: Double = 0
    @Published var endPoint: Double = 0
    @Published var duration: Double = 0
    @Published var thumbnails: [UIImage] = []
    @Published var isPlaying = false
    @Published var previewImage: UIImage?
    @Published var clipID: String? = nil
    
    // 3. 계산 프로퍼티
    /// 현재 트리밍된 영상 길이 (초 단위)
    var currentTrimmedDuration: Double {
        endPoint - startPoint
    }

    // 4. Private 저장 프로퍼티
    private var asset: AVAsset?
    private var imageGenerator: AVAssetImageGenerator?
    private var timeObserverToken: Any?
    private var debounceTimer: Timer?
    private let thumbnailCount = 10

    // 5. init & deinit
    init(
        clipURL: URL,
        cameraSetting: CameraSetting,
        timeStampedTiltList: [TimeStampedTilt]
    ) {
        self.clipURL = clipURL
        self.cameraSetting = cameraSetting
        self.timeStampedTiltList = timeStampedTiltList
        setupPlayer()
    }

    deinit {
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
        }
        debounceTimer?.invalidate()
    }

    /// ViewModel을 초기화할 때 영상 URL을 기반으로 AVAsset과 player를 구성, 썸네일 및 preview 이미지를 준비
    private func setupPlayer() {
        let asset = AVAsset(url: clipURL)
        self.asset = asset

        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero
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
                await updatePreviewImage(at: 0)
                playPreview()

            } catch {
                print("⚠️ Failed to load duration: \(error)")
            }
        }
    }

    /// 영상 전체 길이와 썸네일 간격을 계산하여, 일정 시간 간격으로 트리밍 타임라인 썸네일 이미지 생성
    @MainActor
    private func generateThumbnails(for asset: AVAsset) async {
        thumbnails = []
        let interval = duration / Double(thumbnailCount)
        var images: [UIImage] = []

        for i in 0..<thumbnailCount {
            let time = CMTime(seconds: Double(i) * interval, preferredTimescale: 600)
            do {
                if let cgImage = try imageGenerator?.copyCGImage(at: time, actualTime: nil) {
                    images.append(UIImage(cgImage: cgImage))
                }
            } catch {
                print("⚠️ Thumbnail \(i) error: \(error)")
            }
        }
        self.thumbnails = images
    }

    /// 특정 시간의 프레임을 추출하여 preview 이미지를 갱신
    @MainActor
    func updatePreviewImage(at time: Double) async {
        let time = CMTime(seconds: time, preferredTimescale: 600)
        do {
            if let cgImage = try imageGenerator?.copyCGImage(at: time, actualTime: nil) {
                previewImage = UIImage(cgImage: cgImage)
            }
        } catch {
            print("⚠️ Preview error at \(time): \(error)")
        }
    }

    
    /// 트리밍 시작 지점을 갱신하고, 해당 시점의 프리뷰 이미지를 갱신
    func updateStart(_ value: Double) {
        startPoint = value
        Task { await updatePreviewImage(at: value) }
    }

    /// 트리밍 종료 지점을 갱신하고, 해당 시점의 프리뷰 이미지를 갱신
    func updateEnd(_ value: Double) {
        endPoint = value
        Task { await updatePreviewImage(at: value) }
    }
    

    /// AVPlayer를 지정된 시간으로 이동
    func seek(to time: Double) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
    }

    /// 재생/일시정지 상태 토글 - 현재 상태에 따라 playPreview() 또는 pause를 수행
    func togglePlayback() {
        isPlaying.toggle()
        isPlaying ? playPreview() : player?.pause()
    }
    
    // 썸네일 하나의 너비 계산
    func thumbnailUnitWidth(for thumbnailLineWidth: CGFloat) -> CGFloat {
        let availableWidth = thumbnailLineWidth
        let count = max(thumbnails.count, 1)
        return availableWidth / CGFloat(count)
    }

    // startX 계산 (좌측 핸들의 오른쪽 끝)
    func startX(thumbnailLineWidth: CGFloat, handleWidth: CGFloat) -> CGFloat {
        guard duration > 0 else { return handleWidth }
        let ratio = startPoint / duration
        return handleWidth + ratio * thumbnailLineWidth
    }

    // endX 계산 (우측 핸들의 왼쪽 끝)
    func endX(thumbnailLineWidth: CGFloat, handleWidth: CGFloat) -> CGFloat {
        guard duration > 0 else { return handleWidth + thumbnailLineWidth }
        let ratio = endPoint / duration
        return handleWidth + ratio * thumbnailLineWidth
    }
    
    /// 트리밍 시작 시점부터 재생을 시작하고, 종료 시점에 도달하면 자동으로 정지
    /// 시간 업데이트를 감지하기 위해 AVPlayer에 timeObserver를 등록
    func playPreview() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }

        let currentTime = player?.currentTime() ?? .zero
        let currentTimeSeconds = CMTimeGetSeconds(currentTime)

        /// 재생을 시작하고 종료 시점을 감지하는 로직
        let startPlaybackAndObserve = { [weak self] in
            guard let self = self else { return }
            self.player?.play()
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

        /// 만약 재생이 트리밍 구간 내에서 멈춘 상태라면, 바로 이어서 재생
        if currentTimeSeconds >= startPoint && currentTimeSeconds < endPoint {
            startPlaybackAndObserve()
        } else {
            /// 그렇지 않다면(처음 재생 또는 재생 완료 후), 시작점으로 이동 후 재생
            seek(to: startPoint)
            startPlaybackAndObserve()
        }
    }
    
    /// 드래깅해서 트리밍 박스를 일정 거리만큼 좌우로 이동시키는 함수
    @MainActor
    func shiftTrimmingRange(by delta: Double) {
        let trimmingLength = endPoint - startPoint
        let newStart = max(0, min(startPoint + delta, duration - trimmingLength))
        let newEnd = newStart + trimmingLength

        startPoint = newStart
        endPoint = newEnd
    }
    
    /// Project의 referenceDuration 값을 기반으로
    /// 트리밍 구간(startPoint, endPoint)을 초기화합니다.
    /// 두 번째 촬영 이후부터 호출됩니다.
    @MainActor
    func applyReferenceDuration() {
        guard let projectID = UserDefaults.standard.string(forKey: "currentProjectID"),
              let project = SwiftDataManager.shared.fetchProject(byID: projectID),
              let refDuration = project.referenceDuration
        else {
            print("⚠️ Project not found or referenceDuration is nil")
            return
        }

        self.startPoint = 0
        self.endPoint = min(refDuration, self.duration)
    }
    
    /// `Project` 저장
    /// 첫번째 영상 촬영 시점에 Clip 먼저 저장한 후에 해당 데이터와 nil 상태인 guide를 함께 저장
    /// ProjectID는 UserDefault에도 저장되어 있습니다.
    @MainActor
    func saveProjectData() {
        let clip = saveClipData()
        let cameraSetting = saveCameraSetting()
        let projectID = UUID().uuidString
        // 프로젝트 생성 시간
        let createdAt = Date()
        
        // 프로젝트 이름 자동 생성
        let generatedTitle = generateTimeBasedTitle(from: createdAt)
        
        _ = SwiftDataManager.shared.createProject(
            id: projectID,
            guide: nil,
            clips: [clip],
            cameraSetting: cameraSetting,
            title: generatedTitle,
            referenceDuration: clip.endPoint - clip.startPoint,
            coverImage: nil,
            createdAt: createdAt
        )
    
        SwiftDataManager.shared.saveContext()
        UserDefaults.standard.set(projectID, forKey: "currentProjectID")
    }
    
    /// 시가 기반 이름 자동 생성 함수 - 날짜 Formatter
    private func generateTimeBasedTitle(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HHmm"
        let timeString = formatter.string(from: date)
        return "프로젝트 \(timeString)"
    }
    
    /// clipID를 생성하고, SwiftDataManager를 통해 SwiftData에 저장
    @MainActor
    func saveClipData() -> Clip {
        let clip = createClipData()
        return SwiftDataManager.shared.createClip(clip: clip)
    }
    
    /// 현재 트리밍 상태를 바탕으로 Clip 모델을 생성
    func createClipData() -> Clip {
        let clipID = UUID().uuidString
        self.clipID = clipID
        return Clip(
            id: clipID,
            videoURL: clipURL,
            originalDuration: duration,
            startPoint: startPoint,
            endPoint: endPoint,
            tiltList: timeStampedTiltList,
            heightList: []
        )
    }
    
    @MainActor
    func saveCameraSetting() -> CameraSetting {
        return SwiftDataManager.shared.createCameraSetting(
            zoomScale: cameraSetting.zoomScale,
            isGridEnabled: cameraSetting.isGridEnabled,
            isFrontPosition: cameraSetting.isFrontPosition,
            timerSecond: cameraSetting.timerSecond
        )
    }
    
    /// 기존 Project에 새로운 Clip을 추가
    /// UserDefaults에 저장된 currentProjectID를 기준으로 Project를 찾아 clipList에 추가
    @MainActor
    func appendClipToCurrentProject() {
        let clip = saveClipData()

        guard let projectID = UserDefaults.standard.string(forKey: "currentProjectID"),
              let project = SwiftDataManager.shared.fetchProject(byID: projectID) else {
            print("기존 Project를 찾을 수 없습니다.")
            return
        }

        project.clipList.append(clip)
        SwiftDataManager.shared.saveContext()
    }
}
