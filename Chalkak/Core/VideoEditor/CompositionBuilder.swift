//
//  CompositionBuilder.swift
//  Chalkak
//
//  Created by 석민솔 on 9/16/25.
//

import AVFoundation
import Foundation

/// 비디오 컴포지션 생성을 위한 공통 모듈
struct CompositionBuilder {
    
    /// 컴포지션 생성 결과
    struct CompositionResult {
        let composition: AVMutableComposition
        let videoComposition: AVMutableVideoComposition?
        let totalDuration: CMTime
    }
    
    
    /// 컴포지션 생성 옵션
    struct BuildOptions {
        let needsVideoComposition: Bool
        let preferredTimescale: CMTimeScale
        let frameRate: Int32
        
        static let preview = BuildOptions(
            needsVideoComposition: true,
            preferredTimescale: 600,
            frameRate: 60
        )
        
        static let export = BuildOptions(
            needsVideoComposition: true,
            preferredTimescale: 600,
            frameRate: 60
        )
    }
    
    /// 클립 리스트로부터 컴포지션을 생성
    static func buildComposition<T: ClipInfo>(
        from clips: [T],
        options: BuildOptions = .preview
    ) async throws -> CompositionResult {
        
        guard !clips.isEmpty else {
            throw CompositionError.noClipsProvided
        }
        
        let composition = AVMutableComposition()
        
        // 트랙 생성
        guard let videoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw CompositionError.videoTrackCreationFailed
        }
        
        guard let audioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw CompositionError.audioTrackCreationFailed
        }
        
        // 트랙 삽입
        var cursor = CMTime.zero
        var videoCompositionInstructions: [AVMutableVideoCompositionInstruction] = []
        var renderSize: CGSize?
        
        for clip in clips {
            // URL 유효성 검사
            guard FileManager.isValidVideoFile(at: clip.videoURL) else {
                print("CompositionBuilder: 유효하지 않은 비디오 파일 건너뛰기: \(clip.videoURL)")
                continue
            }
            
            let asset = AVAsset(url: clip.videoURL)
            let startTime = CMTime(seconds: clip.startPoint, preferredTimescale: options.preferredTimescale)
            let endTime = CMTime(seconds: clip.endPoint, preferredTimescale: options.preferredTimescale)
            let duration = CMTime(seconds: clip.endPoint - clip.startPoint, preferredTimescale: options.preferredTimescale)
            let timeRange = CMTimeRange(start: startTime, end: endTime)
            
            do {
                let videoTracks = try await asset.loadTracks(withMediaType: .video)
                let audioTracks = try await asset.loadTracks(withMediaType: .audio)
                
                guard !videoTracks.isEmpty else { continue }
                
                // 비디오 트랙 삽입
                if let sourceVideoTrack = videoTracks.first {
                    try videoTrack.insertTimeRange(timeRange, of: sourceVideoTrack, at: cursor)
                    
                    // 첫 번째 클립의 렌더 사이즈 설정
                    if renderSize == nil && options.needsVideoComposition {
                        let transform = try await sourceVideoTrack.load(.preferredTransform)
                        let size = try await sourceVideoTrack.load(.naturalSize).applying(transform)
                        renderSize = CGSize(width: abs(size.width), height: abs(size.height))
                    }
                    
                    // VideoComposition Instruction 생성 (필요한 경우)
                    if options.needsVideoComposition {
                        let instruction = try await createVideoInstruction(
                            for: videoTrack,
                            sourceTrack: sourceVideoTrack,
                            timeRange: CMTimeRange(start: cursor, duration: duration),
                            cursor: cursor
                        )
                        videoCompositionInstructions.append(instruction)
                    }
                }
                
                // 오디오 트랙 삽입 (있는 경우)
                if let sourceAudioTrack = audioTracks.first {
                    try audioTrack.insertTimeRange(timeRange, of: sourceAudioTrack, at: cursor)
                }
                
                cursor = cursor + duration
                
            } catch {
                print("CompositionBuilder: 트랙 삽입 실패 for clip \(clip.videoURL): \(error)")
                // 실패한 클립은 건너뛰고 계속 진행
                continue
            }
        }
        
        // VideoComposition 생성 (필요한 경우)
        let videoComposition: AVMutableVideoComposition? = options.needsVideoComposition ?
            createVideoComposition(
                instructions: videoCompositionInstructions,
                renderSize: renderSize ?? CGSize(width: 1920, height: 1080),
                frameRate: options.frameRate,
                duration: cursor
            ) : nil
        
        return CompositionResult(
            composition: composition,
            videoComposition: videoComposition,
            totalDuration: cursor
        )
    }
    
    // MARK: - Private 헬퍼 메서드
    private static func createVideoInstruction(
        for compositionTrack: AVMutableCompositionTrack,
        sourceTrack: AVAssetTrack,
        timeRange: CMTimeRange,
        cursor: CMTime
    ) async throws -> AVMutableVideoCompositionInstruction {
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = timeRange
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack)
        let transform = try await sourceTrack.load(.preferredTransform)
        layerInstruction.setTransform(transform, at: cursor)
        
        instruction.layerInstructions = [layerInstruction]
        return instruction
    }
    
    private static func createVideoComposition(
        instructions: [AVMutableVideoCompositionInstruction],
        renderSize: CGSize,
        frameRate: Int32,
        duration: CMTime
    ) -> AVMutableVideoComposition {
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTime(value: 1, timescale: frameRate)
        videoComposition.renderSize = renderSize
        videoComposition.instructions = instructions
        
        return videoComposition
    }
}

// MARK: - 에러 정의
enum CompositionError: Error {
    case noClipsProvided
    case videoTrackCreationFailed
    case audioTrackCreationFailed
}
