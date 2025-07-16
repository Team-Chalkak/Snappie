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
 
 이 클래스는 여러 동영상 파일을 하나로 합쳐서 하나의 동영상 파일로 만들고, (임시)사진 앱에 동영상을 저장합니다
 
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
    
    /// 동영상 자르기 타이밍용 트리밍 정보
    var clipInfoList: [(startTime: CMTime, endTime: CMTime)] = []
    
    // MARK: - init
    /// UserDefaults의 현재 프로젝트 ID를 이용해서 합쳐야 하는 영상 정보를 입력받아서 시작할 수 있도록 생성자 구현
    init() {
        // UserDefaults에서 현재 프로젝트 ID 불러오기
        if let projectID = UserDefaults().string(forKey: "currentProjectID") {
            
            // 프로젝트 ID를 이용해서 SwiftData에서 clipList 가져오기
            Task { @MainActor in
                if let project = SwiftDataManager.shared.fetchProject(byID: projectID) {
                    // URL 정보 저장하기
                    self.videoURLs = project.clipList.map {
                        $0.videoURL
                    }
                    // 트리밍 정보 저장하기
                    self.clipInfoList = project.clipList.map { clip in
                        let startTime = CMTime(seconds: clip.startPoint, preferredTimescale: 600)
                        let endTime = CMTime(seconds: clip.endPoint, preferredTimescale: 600)
                        
                        return (startTime, endTime)
                    }
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    /**
     동영상 URL 배열을 받아서 하나의 동영상으로 합칩니다.
     
     내부적으로 각 비디오 클립을 순서대로 연결하고, 촬영된 비디오를 촬영된 방향과 똑같이 회전시키는 보정 작업을 포함합니다.
     병합이 성공하면 최종 비디오는 Photos 라이브러리에 자동으로 저장됩니다.
     
     - Parameters:
        - urls: 합칠 동영상 URL들의 배열
        - completion: 완료 시 호출될 핸들러. 성공 시 최종 URL, 실패 시 nil
     */
    func mergeVideos() async throws -> URL {
        guard !videoURLs.isEmpty else {
            throw VideoMergerError.noVideosToMerge
        }
        
        // 단일 영상인 경우 바로 반환
        if videoURLs.count == 1, let url = videoURLs.first {
            return url
        }
        
        // UI 상태 업데이트
        isMerging = true
        
        do {
            let assets = videoURLs.map { AVURLAsset(url: $0) }
            let finalURL = try await merge(assets: assets)
            
            // 성공 시 UI 업데이트 및 사진 앱에 저장
            finalVideoURL = finalURL
            
            // 사진 앱에 저장 (필요에 따라 제거 가능)
            try await saveVideoToLibrary(videoURL: finalURL)
            
            isMerging = false
            return finalURL
            
        } catch {
            isMerging = false
            throw error
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
    private func merge(assets: [AVURLAsset]) async throws -> URL {
        // 1. 컴포지션 생성
        let composition = AVMutableComposition()
        var lastTime: CMTime = .zero
        
        // 2. 비디오 트랙 생성
        guard let videoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: Int32(kCMPersistentTrackID_Invalid)
        ) else {
            throw VideoMergerError.videoTrackCreationFailed
        }
        
        // TODO: 오디오 기능 도입되면 주석 해제(ssol)
        // 3. 오디오 트랙 생성
//        guard let audioTrack = composition.addMutableTrack(
//            withMediaType: .audio,
//            preferredTrackID: Int32(kCMPersistentTrackID_Invalid)
//        ) else {
//            throw VideoMergerError.audioTrackCreationFailed
//        }
        
        // 4. 각 애셋을 순차적으로 합치기
        for (index, asset) in assets.enumerated() {
            // 트리밍할 구간 구하기
            let timeRangeToInsert = CMTimeRange(
                start: clipInfoList[index].startTime,
                end: clipInfoList[index].endTime
            )
            
            
            do {
                
                let videoTracks = try await asset.loadTracks(withMediaType: .video)
                guard !videoTracks.isEmpty else { continue }
                
                // TODO: 오디오 기능 도입되면 주석 해제(ssol)
//            // 오디오 트랙이 있으면 추가
//            let audioTracks = try await asset.loadTracks(withMediaType: .audio)
//            guard !audioTracks.isEmpty else { continue }
                
                // 비디오
                try videoTrack.insertTimeRange(timeRangeToInsert, of: videoTracks[0], at: lastTime)
                
                // TODO: 오디오 기능 도입되면 주석 해제(ssol)
//                try audioTrack.insertTimeRange(timeRangeToInsert, of: audioTracks[0], at: lastTime)
                
                lastTime = CMTimeAdd(lastTime, timeRangeToInsert.duration)
                
                print("영상 \(index + 1)/\(assets.count) 추가 완료")
            } catch {
                print("영상 \(index + 1) 추가 실패: \(error.localizedDescription)")
                throw VideoMergerError.unknown(error)
            }
        }
        
        // 5. 출력 URL 생성
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory() + "\(UUID().uuidString).mp4")
        
        // 6. 비디오 컴포지션 생성
        let videoComposition = createVideoComposition(for: videoTrack, duration: lastTime)
        
        // 7. 익스포트 세션 생성
        guard let exporter = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw VideoMergerError.exportFailed
        }
        
        // 익스포트 설정
        exporter.outputFileType = .mp4
        exporter.outputURL = tempURL
        exporter.videoComposition = videoComposition
        
        // 8. 비동기 익스포트 실행
        return try await withCheckedThrowingContinuation { continuation in
            exporter.exportAsynchronously {
                switch exporter.status {
                case .completed:
                    guard let url = exporter.outputURL else {
                        continuation.resume(throwing: VideoMergerError.exportURLNotFound)
                        return
                    }
                    print("영상 합치기 완료: \(url)")
                    continuation.resume(returning: url)
                    
                case .failed:
                    let error = exporter.error ?? VideoMergerError.exportFailed
                    print("영상 합치기 실패: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    
                case .cancelled:
                    continuation.resume(throwing: VideoMergerError.exportCancelled)
                    
                default:
                    continuation.resume(throwing: VideoMergerError.unknown(NSError(domain: "VideoMerger", code: -1, userInfo: [NSLocalizedDescriptionKey: "예상치 못한 상태"])))
                }
            }
        }
    }
    
    /**
    비디오 트랙에 90도 회전 보정을 적용한 비디오 컴포지션을 생성합니다.

    세로로 촬영된 비디오가 가로로 저장되는 이슈를 해결하기 위해 회전 변환을 적용합니다.

    - Parameters:
       - videoTrack: 회전 보정을 적용할 비디오 트랙
       - duration: 최종 비디오의 총 재생 시간
    - Returns: 회전 보정이 적용된 비디오 컴포지션
    */
    private func createVideoComposition(for videoTrack: AVMutableCompositionTrack, duration: CMTime) -> AVMutableVideoComposition {
        // 비디오 회전 보정 설정
        let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        
        var transform = CGAffineTransform.identity
        transform = transform.rotated(by: 90 * (.pi / 180))
        transform = transform.translatedBy(x: 0, y: -videoTrack.naturalSize.height)
        layerInstructions.setTransform(transform, at: .zero)
        
        // 컴포지션 인스트럭션 생성
        let instructions = AVMutableVideoCompositionInstruction()
        instructions.timeRange = CMTimeRange(start: .zero, duration: duration)
        instructions.layerInstructions = [layerInstructions]
        
        // 비디오 컴포지션 설정
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(
            width: videoTrack.naturalSize.height,
            height: videoTrack.naturalSize.width
        )
        videoComposition.instructions = [instructions]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        return videoComposition
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

// VideoMerger에서 발생할 수 있는 커스텀 에러 정의
enum VideoMergerError: Error, LocalizedError {
    case noVideosToMerge
    case exportFailed
    case exportCancelled
    case exportURLNotFound
    case videoTrackCreationFailed
    case audioTrackCreationFailed
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .noVideosToMerge: return "합칠 동영상이 없습니다."
        case .exportFailed: return "비디오 익스포트에 실패했습니다."
        case .exportCancelled: return "비디오 익스포트가 중단되었습니다."
        case .exportURLNotFound: return "익스포트된 비디오의 URL을 찾을 수 없습니다."
        case .videoTrackCreationFailed: return "비디오 트랙 생성에 실패했습니다."
        case .audioTrackCreationFailed: return "오디오 트랙 생성에 실패했습니다."
        case .unknown(let error): return "알 수 없는 오류가 발생했습니다: \(error.localizedDescription)"
        }
    }
}
