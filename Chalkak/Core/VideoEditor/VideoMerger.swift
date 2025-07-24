//
//  VideoMerger.swift
//  Chalkak
//
//  Created by 석민솔 on 7/16/25.
//

import AVFoundation
import Foundation

 /**
  여러 비디오 파일을 하나의 파일로 병합하는 기능을 제공하는 구조체

 - `VideoMerger`는 여러 동영상 클립을 하나로 합쳐서 하나의 동영상 파일로 만듭니다.
 각 클립의 트리밍 정보를 기반으로 원하는 구간만 추출하여 병합할 수 있습니다.
  
  - 주로 `VideoManager`에서 호출해서 동영상을 합치는 기능을 담당할 때 사용됩니다

 ## 사용 예시
 ```swift
 let videoMerger = VideoMerger()
 let clips = [
     Clip(videoURL: url1, startPoint: 0, endPoint: 10),
     Clip(videoURL: url2, startPoint: 5, endPoint: 15),
     Clip(videoURL: url3, startPoint: 2, endPoint: 8)
 ]

 Task {
     do {
         let mergedVideoURL = try await videoMerger.mergeVideos(from: clips)
         print("병합 완료: \(mergedVideoURL)")
     } catch {
         print("병합 실패: \(error.localizedDescription)")
     }
 }
 ```
 */
struct VideoMerger {
    
    /// 여러 비디오 클립을 하나로 병합합니다.
    ///
    /// - Parameter clipList: 병합할 비디오 클립들의 배열
    /// - Returns: 병합된 비디오 파일의 URL
    /// - Throws: `VideoMergerError` 타입의 에러
    func mergeVideos(from clipList: [Clip]) async throws -> URL {
        guard !clipList.isEmpty else {
            throw VideoMergerError.noVideosToMerge
        }
        
        // 단일 영상인 경우 바로 반환
        if clipList.count == 1, let url = clipList.first?.videoURL {
            return url
        }
        
        // clipList에서 정보 빼오기
        let (videoURLs, trimmingInfoList) = getURLsAndTrimInfo(from: clipList)
        
        
        do {
            // 영상 합치기
            let assets = videoURLs.map { AVURLAsset(url: $0) }
            let finalURL = try await merge(assets: assets, trimmingInfoList: trimmingInfoList)
            
            return finalURL
            
        } catch {
            throw error
        }
    }
    
    // MARK: - 내부 메서드
    /// 클립 리스트에서 URL과 트리밍 정보를 추출합니다.
    private func getURLsAndTrimInfo(from clipList: [Clip]) -> (
        urlList: [URL],
        trimmingInfoList: [(startTime: CMTime, endTime: CMTime)]
    ) {
        // URL 정보 저장하기
        let urlList = clipList.map {
            $0.videoURL
        }
        // 트리밍 정보 저장하기
        let trimmingInfoList = clipList.map {
            let startTime = CMTime(seconds: $0.startPoint, preferredTimescale: 600)
            let endTime = CMTime(seconds: $0.endPoint, preferredTimescale: 600)
            
            return (startTime, endTime)
        }
        
        return (urlList, trimmingInfoList)
    }
    
    /// 여러 동영상 애셋을 하나로 합칩니다.
    ///
    /// 내부적으로만 호출하는 메서드입니다.
    ///
    /// - Parameters:
    ///   - assets: 병합할 비디오 애셋들
    ///   - trimmingInfoList: 각 애셋의 트리밍 정보
    /// - Returns: 병합된 비디오 파일의 URL
    /// - Throws: `VideoMergerError` 타입의 에러
    private func merge(assets: [AVURLAsset], trimmingInfoList: [(startTime: CMTime, endTime: CMTime)]) async throws -> URL {
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
                start: trimmingInfoList[index].startTime,
                end: trimmingInfoList[index].endTime
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
        return try await export(exporter:exporter)
    }
    
    /// 비디오 익스포트를 실행하고 결과를 반환합니다.
    private func export(exporter: AVAssetExportSession) async throws -> URL {
        await exporter.export()
        
        switch exporter.status {
        case .completed:
            guard let url = exporter.outputURL else { throw VideoMergerError.exportURLNotFound }
            return url
        case .failed:
            throw exporter.error ?? VideoMergerError.exportFailed
        case .cancelled:
            throw VideoMergerError.exportCancelled
        default:
            throw VideoMergerError.unknown(NSError(domain: "VideoMerger", code: -1, userInfo: [NSLocalizedDescriptionKey: "예상치 못한 익스포트 상태"]))
        }
    }
    
    /// 비디오 트랙에 90도 회전 보정을 적용한 비디오 컴포지션을 생성합니다.
    ///
    /// 세로로 촬영된 비디오가 가로로 저장되는 이슈를 해결하기 위해 회전 변환을 적용합니다.
    ///
    /// - Parameters:
    ///    - videoTrack: 회전 보정을 적용할 비디오 트랙
    ///    - duration: 최종 비디오의 총 재생 시간
    /// - Returns: 회전 보정이 적용된 비디오 컴포지션
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
        // 내보내기 사양 60fps 설정
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 60)
        
        return videoComposition
    }
}

/// VideoMerger에서 발생할 수 있는 커스텀 에러
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
