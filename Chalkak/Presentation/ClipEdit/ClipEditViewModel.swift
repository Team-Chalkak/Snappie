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

@Observable
@MainActor
final class ClipEditViewModel {
    // 1. Input
    var clipURL: URL
    var cameraSetting: CameraSetting
    var timeStampedTiltList: [TimeStampedTilt]

    var startPoint: Double = 0
    var endPoint: Double = 0
    var duration: Double = 0
    var thumbnails: [UIImage] = []
    var previewImage: UIImage?
    var clipID: String?

    /// 현재 트리밍된 영상 길이 (초 단위)
    var currentTrimmedDuration: Double {
        endPoint - startPoint
    }

    private var asset: AVAsset?
    private var trimOffset: Double = 0

    // 서비스 로직
    private let playerService = VideoPlayerService()
    private let thumbnailService = ThumbnailService()
    private let clipRepository = ClipRepository()

    var player: AVPlayer? { playerService.player }
    var isPlaying: Bool { playerService.isPlaying }

    init(
        clipURL: URL,
        cameraSetting: CameraSetting,
        timeStampedTiltList: [TimeStampedTilt],
        clipID: String? = nil
    ) {
        self.clipURL = clipURL
        self.cameraSetting = cameraSetting
        self.timeStampedTiltList = timeStampedTiltList
        self.clipID = clipID
        setupPlayer()
    }

    /// ViewModel을 초기화할 때 영상 URL을 기반으로 AVAsset과 player를 구성, 썸네일 및 preview 이미지를 준비
    private func setupPlayer() {
        let asset = AVAsset(url: clipURL)
        self.asset = asset

        thumbnailService.setupImageGenerator(asset: asset)

        Task {
            do {
                let durationCMTime = try await asset.load(.duration)
                let durationSeconds = CMTimeGetSeconds(durationCMTime)

                await MainActor.run {
                    self.duration = durationSeconds

                    if let clipID,
                       let savedClip = SwiftDataManager.shared.fetchClip(byID: clipID)
                    {
                        // clipID가 있는 경우 트리밍 정보를 가져옴
                        self.startPoint = savedClip.startPoint
                        self.endPoint = savedClip.endPoint
                    } else {
                        // 아이디가 없는 새촬영일때
                        self.startPoint = 0
                        self.endPoint = durationSeconds
                    }

                    // Player 생성 → Service로 위임
                    let playerItem = AVPlayerItem(asset: asset)
                    self.playerService.player = AVPlayer(playerItem: playerItem)
                }

                // 썸네일 생성
                thumbnails = await thumbnailService.generateThumbnails(duration: self.duration)
                await updatePreviewImage(at: self.startPoint)
                playPreview()

            } catch {
                print("⚠️ Failed to load duration: \(error)")
            }
        }
    }

    /// 특정 시간의 프레임을 추출하여 preview 이미지를 갱신
    @MainActor
    func updatePreviewImage(at time: Double) async {
        previewImage = await thumbnailService.updatePreviewImage(at: time, trimOffset: trimOffset)
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

    /// 재생 일시정지
    func pause() {
        playerService.pause()
    }

    /// AVPlayer를 지정된 시간으로 이동
    func seek(to time: Double) {
        playerService.seek(to: time, trimOffset: trimOffset)
    }

    /// 재생/일시정지 상태 토글 - 현재 상태에 따라 playPreview() 또는 pause를 수행
    func togglePlayback() {
        playerService.togglePlayback(
            startPoint: startPoint,
            endPoint: endPoint,
            trimOffset: trimOffset,
            onPlayPreview: { [weak self] in
                self?.playPreview()
            }
        )
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
    func playPreview() {
        playerService.playPreview(
            startPoint: startPoint,
            endPoint: endPoint,
            trimOffset: trimOffset,
            onSeek: { [weak self] time in
                self?.seek(to: time)
            }
        )
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

    /// GuideSelectView에서 트리밍된 구간만 보여주게끔 조정
    @MainActor
    func trimmedClip(trimStart: Double, trimEnd: Double) async {
        // 원본시간
        trimOffset = trimStart

        // 사용자가 보기에 시작은 0초로 고정
        let trimmedDuration = trimEnd - trimStart
        startPoint = 0
        duration = trimmedDuration
        endPoint = trimmedDuration

        seek(to: 0)

        await updatePreviewImage(at: 0)

        // 트리밍된 구간의 썸네일 생성
        thumbnails = await thumbnailService.generateTrimmedThumbnails(
            trimStart: trimStart,
            trimEnd: trimEnd
        )
    }

    /// Project의 referenceDuration 값을 기반으로
    /// 트리밍 구간(startPoint, endPoint)을 초기화합니다.
    /// 두 번째 촬영 이후부터 호출됩니다.
    @MainActor
    func applyReferenceDuration() {
        guard let projectID = UserDefaults.standard.string(forKey: UserDefaultKey.currentProjectID),
              let project = SwiftDataManager.shared.fetchProject(byID: projectID),
              let refDuration = project.referenceDuration
        else {
            print("⚠️ Project not found or referenceDuration is nil")
            return
        }

        startPoint = 0
        endPoint = min(refDuration, duration)
    }

    /// clipID 생성 및 저장
    @MainActor
    func saveClipData() -> Clip? {
        let clip = createClipData()
        do {
            try clipRepository.save(clip)
            return clip
        } catch {
            print("clip 생성 실패: \(error)")
            return nil
        }
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
            tiltList: timeStampedTiltList
        )
    }

    /// 기존 Project에 새로운 Clip을 추가
    /// UserDefaults에 저장된 currentProjectID를 기준으로 Project를 찾아 clipList에 추가
    @MainActor
    func appendClipToCurrentProject() {
        guard let newClip = saveClipData() else {
            return
        }

        guard let projectID = UserDefaults.standard.string(forKey: UserDefaultKey.currentProjectID) else {
            print("⚠️ currentProjectID가 없습니다.")
            return
        }

        do {
            try clipRepository.appendToProject(clip: newClip, projectID: projectID)
        } catch {
            print("기존 Project를 찾을 수 없습니다.")
        }
    }

    // MARK: - 유저 디폴트

    // 1. 현재 currentProjectID 가져오기
    func fetchCurrentProjectID() -> String? {
        if let projectID = UserDefaults.standard.string(forKey: UserDefaultKey.currentProjectID) {
            return projectID
        } else {
            print("⚠️ currentProjectID가 없습니다.")
            return nil
        }
    }

    // 2. currentProjectID nil로 초기화
    func clearCurrentProjectID() {
        UserDefaults.standard.set(nil, forKey: UserDefaultKey.currentProjectID)
    }

    // MARK: - Temp 관련 메소드

    func createTempClip() -> Clip {
        return Clip(
            id: UUID().uuidString,
            videoURL: clipURL,
            originalDuration: duration,
            startPoint: startPoint,
            endPoint: endPoint,
            tiltList: timeStampedTiltList,
            isTemp: true,
            originalClipID: nil
        )
    }
}

// MARK: - 클립 수정 내용 임시 저장 (`ProjectEdit` 화면에서 수정 버튼을 통해 넘어온 경우)

extension ClipEditViewModel {
    /// 클립 수정 내용 임시 저장
    @MainActor
    func updateClipInTempProject() {
        guard let clipID = clipID else {
            return
        }

        // 클립 업데이트
        clipRepository.updatePoints(
            id: clipID,
            start: startPoint,
            end: endPoint
        )
    }
}
