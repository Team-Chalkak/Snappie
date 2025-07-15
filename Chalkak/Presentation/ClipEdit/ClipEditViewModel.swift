//
//  ClipEditViewModel.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//
import Foundation
import SwiftData
import AVFoundation
import UIKit

final class ClipEditViewModel: ObservableObject {
    private var modelContext: ModelContext?
    private var asset: AVAsset?
    private var imageGenerator: AVAssetImageGenerator?
    private var timeObserverToken: Any?
    private var debounceTimer: Timer?

    private let thumbnailCount = 10  // 썸네일 개수는 여기서만 관리
    
    @Published var player: AVPlayer?
    @Published var startPoint: Double = 0
    @Published var endPoint: Double = 0
    @Published var duration: Double = 0
    @Published var thumbnails: [UIImage] = []
    @Published var isPlaying = false
    @Published var previewImage: UIImage?
    
    // 로딩 및 화면 전환 상태
    @Published var isLoading = false
    @Published var isOverlayReady = false
    
    // 관리 객체
    let extractor = VideoFrameExtractor()
    let overlayManager = OverlayManager()

    //TODO: - 더미 영상 경로 : 이후 스위프트 데이터에서 가져오도록 수정해야함
    public var dummyURL: URL? = Bundle.main.url(forResource: "sample-video", withExtension: "mov")

    init(context: ModelContext?) {
        self.modelContext = context
        // 관리 객체 연결
        extractor.overlayManager = overlayManager
        setupPlayer()
    }
    
    deinit {
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
        }
        debounceTimer?.invalidate()
    }

    func updateContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    //MARK: - 클립 편집 화면 관련 함수
    ///프리뷰 플레이어 셋업
    private func setupPlayer() {
        guard let url = dummyURL else {
            print("❌ dummyURL is nil")
            return
        }

        let asset = AVAsset(url: url)
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

            } catch {
                print("⚠️ Failed to load duration: \(error)")
            }
        }
    }

    ///클립타임라인(TrimmingLine) 생성
    @MainActor
    private func generateThumbnails(for asset: AVAsset) async {
        thumbnails = []

        let interval = duration / Double(thumbnailCount)
        var images: [UIImage] = []

        for i in 0..<thumbnailCount {
            let time = CMTime(seconds: Double(i) * interval, preferredTimescale: 600)
            do {
                if let cgImage = try imageGenerator?.copyCGImage(at: time, actualTime: nil) {
                    let uiImage = UIImage(cgImage: cgImage)
                    images.append(uiImage)
                }
            } catch {
                print("⚠️ Failed to generate thumbnail at \(i): \(error)")
            }
        }

        self.thumbnails = images
    }

    ///핸들 움직일 때, 프리뷰 이미지도 업데이트 되게
    @MainActor
    func updatePreviewImage(at time: Double) async {
        let time = CMTime(seconds: time, preferredTimescale: 600)
        do {
            if let cgImage = try imageGenerator?.copyCGImage(at: time, actualTime: nil) {
                previewImage = UIImage(cgImage: cgImage)
            }
        } catch {
            print("⚠️ Failed to generate preview image at \(time): \(error)")
        }
    }

    /// 스타트 포인트 변경
    func updateStart(_ value: Double) {
        startPoint = value
        Task {
            await updatePreviewImage(at: value)
        }
    }

    /// 엔드 포인트 변경
    func updateEnd(_ value: Double) {
        endPoint = value
        Task {
            await updatePreviewImage(at: value)
        }
    }

    func seek(to time: Double) {
        player?.seek(
            to: CMTime(seconds: time, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
    }
    
    /// 재생/일시정지 버튼
    func togglePlayback() {
        isPlaying.toggle()
        if isPlaying {
            playPreview()
        } else {
            player?.pause()
        }
    }
    
    /// 프리뷰 재생
    func playPreview() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        
        player?.seek(to: CMTime(seconds: startPoint, preferredTimescale: 600)) { [weak self] _ in
            guard let self = self else { return }
            
            self.player?.play()
            self.isPlaying = true
            
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
    }
    
    //MARK: - 실루엣 오버레이 추출 및 저장 관련 함수
    /// 트리밍 후 '다음' 버튼 액션
    func prepareOverlay() {
        guard let url = dummyURL else { return }
        
        isLoading = true
        
        extractor.extractFrame(from: url, at: startPoint) {
            /// 실루엣 오버레이 추출 완료 후
            self.isLoading = false
            self.isOverlayReady = true
        }
    }
    
    /// 실루엣 오버레이 생성 화면에서 '뒤로가기' 버튼 눌렀을 때 가이드 관련 내용 초기화
    func dismissOverlay() {
        isOverlayReady = false
        isLoading = false
        overlayManager.outlineImage = nil
        overlayManager.maskedCIImage = nil
        overlayManager.maskedUIImage = nil
        extractor.extractedImage = nil
        extractor.extractedCIImage = nil
    }
    
    /// 실루엣 오버레이 객체 잘 저장되는지 확인
    func createGuideForLog() {
        guard let outlineImage = overlayManager.outlineImage,
              let bBox = overlayManager.boundingBox else {
            print("❌ 로그 출력을 위한 정보가 부족합니다.")
            return
        }
        
        let dummyClipID = "DUMMY_CLIP_ID"
        
        let newGuide = Guide(
            clipID: dummyClipID,
            bBoxPosition: bBox.origin,
            bBoxScale: bBox.width,
            outlineImage: outlineImage,
            cameraTilt: Tilt(degreeX: 0, degreeZ: 0), // 임시값
            cameraHeight: 1.0 // 임시값
        )
        
        print("--- 생성된 가이드 정보 ---")
        print("Clip ID: \(newGuide.clipID)")
        print("Bounding Box Position: \(newGuide.bBoxPosition)")
        print("Bounding Box Scale: \(newGuide.bBoxScale)")
        print("Camera Tilt: \(newGuide.cameraTilt)")
        print("Camera Height: \(newGuide.cameraHeight)")
        print("Outline Image Data Size: \(newGuide.outlineImageData.count) bytes")
        print("-------------------------")
    }
}

