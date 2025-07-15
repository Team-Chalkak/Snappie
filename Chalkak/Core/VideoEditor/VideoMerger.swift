//
//  VideoMerger.swift
//  Chalkak
//
//  Created by 석민솔 on 7/16/25.
//

import AVFoundation
import Foundation
import Photos

/**
 여러 비디오 파일을 하나의 파일로 병합하는 기능을 제공하는 클래스
 
 이 클래스는 여러 동영상 파일을 하나로 합쳐서 하나의 동영상 파일로 만들고, 사진 앱에 동영상을 저장합니다(임시)
 
 ## 사용 예시
 ```swift
 // 1. VideoMerger 인스턴스 생성
 let merger = VideoMerger()
 
 // 2. 합치고 싶은 비디오들의 URL 배열 준비
 let videoURLs = [url1, url2, url3] // 합칠 동영상 URL들
 
 // 3. mergeVideos 메서드 호출
 merger.mergeVideos(from: videoURLs) { finalURL in
     if let finalURL = finalURL {
         print("합치기 완료: \(finalURL)")
         // 최종 동영상 사용
     } else {
         print("합치기 실패")
     }
 }
 ```
 */
class VideoMerger: ObservableObject {
    
    // MARK: - Properties
    
    /// 합칠 동영상 파일들의 URL 배열
    @Published var videoURLs: [URL] = []
    
    /// 최종 합쳐진 동영상의 URL
    @Published var finalVideoURL: URL?
    
    /// 현재 합치기 작업 진행 중인지 여부
    @Published var isMerging: Bool = false
    
    // MARK: - Public Methods
    
    /**
     동영상 URL 배열을 받아서 하나의 동영상으로 합칩니다.
     
     내부적으로 각 비디오 클립을 순서대로 연결하고, 촬영된 비디오를 촬영된 방향과 똑같이 회전시키는 보정 작업을 포함합니다.
     병합이 성공하면 최종 비디오는 Photos 라이브러리에 자동으로 저장됩니다.
     
     - Parameters:
        - urls: 합칠 동영상 URL들의 배열
        - completion: 완료 시 호출될 핸들러. 성공 시 최종 URL, 실패 시 nil
     */
    func mergeVideos(from urls: [URL], completion: @escaping (URL?) -> Void) {
        guard !urls.isEmpty else {
            completion(nil)
            return
        }
        
        // 단일 영상인 경우
        if urls.count == 1 {
            completion(urls.first)
            return
        }
        
        // 여러 영상을 합치는 경우
        self.videoURLs = urls
        self.isMerging = true
        
        let assets = urls.map { AVURLAsset(url: $0) }
        
        // TODO: Deprecated된 코드 업그레이드 필요(ssol)
        mergeVideos(assets: assets) { exporter in
            exporter.exportAsynchronously {
                DispatchQueue.main.async {
                    self.isMerging = false
                    
                    if exporter.status == .failed {
                        print("영상 합치기 실패: \(exporter.error?.localizedDescription ?? "알 수 없는 오류")")
                        completion(nil)
                    } else {
                        if let finalURL = exporter.outputURL {
                            print("영상 합치기 완료: \(finalURL)")
                            self.finalVideoURL = finalURL
                            // TODO: 미리보기로 구현하고 해당 로직은 삭제 필요(ssol)
                            // 자동으로 사진 앱에 저장
                            Task {
                                await self.saveVideoToLibrary(videoURL: finalURL)
                            }
                            
                            completion(finalURL)
                        } else {
                            completion(nil)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 내부 메서드
    
    /**
     여러 동영상 애셋을 하나로 합칩니다.
     
     내부적으로만 호출하는 메서드이기 때문에 외부에서는 활용하지 않습니다.
     
     이 메서드의 주요 기능:
     1. 새로운 컴포지션 생성
     2. 비디오 트랙과 오디오 트랙 추가
     3. 각 영상을 순차적으로 연결
     4. 90도 회전 보정 적용
     5. 최종 영상 익스포트 준비
     
     - Parameters:
        - assets: 합칠 동영상 애셋들의 배열
        - completion: 익스포트 세션을 반환하는 완료 핸들러
     */
    private func mergeVideos(
        assets: [AVURLAsset],
        completion: @escaping (AVAssetExportSession) -> Void
    ) {
        // 1. 새로운 컴포지션 생성
        let composition = AVMutableComposition()
        var lastTime: CMTime = .zero
        
        // 2. 비디오 트랙 생성
        guard let videoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: Int32(kCMPersistentTrackID_Invalid)
        ) else {
            print("비디오 트랙 생성 실패")
            return
        }
        
        // TODO: 오디오 기능 도입되면 주석 해제(ssol)
//        // 3. 오디오 트랙 생성
//        guard let audioTrack = composition.addMutableTrack(
//            withMediaType: .audio,
//            preferredTrackID: Int32(kCMPersistentTrackID_Invalid)
//        ) else {
//            print("오디오 트랙 생성 실패")
//            return
//        }
        
        // 4. 각 애셋을 순차적으로 합치기
        for (index, asset) in assets.enumerated() {
            do {
                // 비디오 트랙 추가
                let videoTracks = asset.tracks(withMediaType: .video)
                if !videoTracks.isEmpty {
                    try videoTrack.insertTimeRange(
                        CMTimeRange(start: .zero, duration: asset.duration),
                        of: videoTracks[0],
                        at: lastTime
                    )
                }
                
                // TODO: 오디오 기능 도입되면 주석 해제(ssol)
//                // 오디오 트랙이 있으면 추가
//                let audioTracks = asset.tracks(withMediaType: .audio)
//                if !audioTracks.isEmpty {
//                    try audioTrack.insertTimeRange(
//                        CMTimeRange(start: .zero, duration: asset.duration),
//                        of: audioTracks[0],
//                        at: lastTime
//                    )
//                }
                
                print("영상 \(index + 1)/\(assets.count) 추가 완료")
            } catch {
                print("영상 \(index + 1) 추가 실패: \(error.localizedDescription)")
            }
            
            // 다음 영상이 시작될 시간 계산
            lastTime = CMTimeAdd(lastTime, asset.duration)
        }
        
        // 5. 최종 출력 파일 경로 생성
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory() + "\(UUID().uuidString).mp4")
        
        // 6. 비디오 회전 보정 설정(세로로 찍었는데 가로로 저장되는 이슈 해결)
        let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        
        var transform = CGAffineTransform.identity
        transform = transform.rotated(by: 90 * (.pi / 180))        // 90도 회전
        transform = transform.translatedBy(x: 0, y: -videoTrack.naturalSize.height)  // 위치 조정
        layerInstructions.setTransform(transform, at: .zero)
        
        // 7. 컴포지션 인스트럭션 생성
        let instructions = AVMutableVideoCompositionInstruction()
        instructions.timeRange = CMTimeRange(start: .zero, duration: lastTime)
        instructions.layerInstructions = [layerInstructions]
        
        // 8. 비디오 컴포지션 설정
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(
            width: videoTrack.naturalSize.height,   // 회전으로 인해 width/height 교체
            height: videoTrack.naturalSize.width
        )
        videoComposition.instructions = [instructions]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)  // 30fps
        
        // 9. 익스포트 세션 생성
        guard let exporter = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            print("익스포트 세션 생성 실패")
            return
        }
        
        // 10. 익스포트 설정
        exporter.outputFileType = .mp4
        exporter.outputURL = tempURL
        exporter.videoComposition = videoComposition
        
        // 11. 완료 핸들러 호출
        completion(exporter)
    }
    
    /**
     임시 파일들을 정리합니다.
     
     합치기 작업이 완료된 후 원본 파일들을 삭제하고 싶을 때 사용합니다.
     */
    func cleanupTemporaryFiles() {
        for url in videoURLs {
            try? FileManager.default.removeItem(at: url)
        }
        videoURLs.removeAll()
    }
}

// TODO: - 미리보기 네비게이션 구현하면서 이 파일에서 해당 갤러리 저장 로직은 삭제될 예정(ssol)
// MARK: Photos 앱에 데이터 저장
extension VideoMerger {
    @MainActor
    private func saveVideoToLibrary(videoURL: URL) async {
        let authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch authorizationStatus {
        case .notDetermined:
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            if status == .authorized || status == .limited {
                await performVideoSave(videoURL: videoURL)
            } else {
                print("라이브러리 권한 거부")
            }
        case .authorized, .limited:
            await performVideoSave(videoURL: videoURL)
        default:
            print("라이브러리 접근 권한 없음")
        }
    }
    
    private func performVideoSave(videoURL: URL) async {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }
        } catch {
            print("동영상 저장 에러\(error.localizedDescription)")
        }
    }
}
