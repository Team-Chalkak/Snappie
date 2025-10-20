//
//  AVMutableComposition.swift
//  Chalkak
//
//  Created by 배현진 on 7/28/25.
//

import AVFoundation

extension AVMutableComposition {
    /// editableClips와 trimming 범위를 사용해서,
    /// 각 세그먼트마다 원본 preferredTransform을 적용한 VideoComposition 생성
    func makePreviewVideoComposition(
        using editableClips: [EditableClip]
    ) -> AVMutableVideoComposition {
        // 합성된 트랙
        guard let compTrack = tracks(withMediaType: .video).first else {
            fatalError("Video track 없음")
        }
        
        // VideoComposition 틀 설정
        let videoComp = AVMutableVideoComposition()
        videoComp.frameDuration = CMTime(value: 1, timescale: 60)
        
        // 각 클립별 Instruction 생성
        var cursor = CMTime.zero
        var instructions: [AVMutableVideoCompositionInstruction] = []
        
        for clip in editableClips {
            // 원본 에셋 로드
            let asset = AVAsset(url: clip.videoURL)
            guard let assetTrack = asset.tracks(withMediaType: .video).first else {
                continue
            }
            
            // 이 클립의 표시 구간
            let duration = CMTime(seconds: clip.trimmedDuration, preferredTimescale: 600)
            let timeRange = CMTimeRange(start: cursor, duration: duration)
            
            // Instruction & LayerInstruction
            let instr = AVMutableVideoCompositionInstruction()
            instr.timeRange = timeRange
            
            let layerInstr = AVMutableVideoCompositionLayerInstruction(assetTrack: compTrack)
            // 클립마다 다른 preferredTransform 적용
            let t = assetTrack.preferredTransform
            layerInstr.setTransform(t, at: cursor)
            
            instr.layerInstructions = [layerInstr]
            instructions.append(instr)
            
            // 다음 클립 시작 시점으로 이동
            cursor = cursor + duration
        }
        
        // renderSize 계산 (첫 클립 기준으로)
        if let firstClip = editableClips.first,
           let firstAsset = AVAsset(url: firstClip.videoURL).tracks(withMediaType: .video).first
        {
            let t = firstAsset.preferredTransform
            let size = firstAsset.naturalSize.applying(t)
            videoComp.renderSize = CGSize(width: abs(size.width), height: abs(size.height))
        }
        
        videoComp.instructions = instructions
        return videoComp
    }
}
