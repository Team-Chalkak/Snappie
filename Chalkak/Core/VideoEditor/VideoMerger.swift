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
    /// 여러 비디오 클립을 하나로 병합
    func mergeVideos(from clipList: [Clip]) async throws -> URL {
        guard !clipList.isEmpty else {
            throw VideoMergerError.noVideosToMerge
        }
        
        // 단일 영상인 경우 바로 반환
        if clipList.count == 1, let url = clipList.first?.videoURL {
            return url
        }
        
        do {
            // CompositionBuilder를 사용하여 컴포지션 생성
            let result = try await CompositionBuilder.buildComposition(
                from: clipList,
                options: .export
            )
            
            // 출력 URL 생성
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory() + "\(UUID().uuidString).mp4")
            
            // 익스포트 실행
            let finalURL = try await export(
                composition: result.composition,
                videoComposition: result.videoComposition,
                to: tempURL
            )
            
            return finalURL
            
        } catch {
            throw error
        }
    }
    
    /// 컴포지션을 파일로 익스포트합니다.
    private func export(
        composition: AVMutableComposition,
        videoComposition: AVMutableVideoComposition?,
        to outputURL: URL
    ) async throws -> URL {
        
        guard let exporter = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw VideoMergerError.exportFailed
        }
        
        exporter.outputFileType = .mp4
        exporter.outputURL = outputURL
        exporter.videoComposition = videoComposition
        
        await exporter.export()
        
        switch exporter.status {
        case .completed:
            guard let url = exporter.outputURL else {
                throw VideoMergerError.exportURLNotFound
            }
            return url
        case .failed:
            throw exporter.error ?? VideoMergerError.exportFailed
        case .cancelled:
            throw VideoMergerError.exportCancelled
        default:
            throw VideoMergerError.unknown(
                NSError(domain: "VideoMerger", code: -1,
                       userInfo: [NSLocalizedDescriptionKey: "예상치 못한 익스포트 상태"])
            )
        }
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
