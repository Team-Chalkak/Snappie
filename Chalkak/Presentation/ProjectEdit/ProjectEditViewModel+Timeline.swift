//
//  ProjectEditViewModel+Timeline.swift
//  Chalkak
//
//  Created by 석민솔 on 12/23/24.
//

import Foundation

extension ProjectEditViewModel {

    private var timelineClipWidth: CGFloat { 62 }
    private var timelineClipSpacing: CGFloat { 3 }

    private func effectiveWidth(for clipIndex: Int) -> CGFloat {
        clipIndex < editableClips.count - 1
            ? timelineClipWidth + timelineClipSpacing
            : timelineClipWidth
    }

    /// playTime(초) → pixel offset
    func pixelOffset(for playTime: Double) -> CGFloat {
        // 클립이 없으면 0 반환
        guard !editableClips.isEmpty else { return 0 }

        var accumulatedTime: Double = 0
        var accumulatedPixel: CGFloat = 0

        for (index, clip) in editableClips.enumerated() {
            let clipEndTime = accumulatedTime + clip.trimmedDuration

            if playTime <= clipEndTime {
                let timeInClip = playTime - accumulatedTime
                let effective = effectiveWidth(for: index)

                // division by zero 방지
                guard clip.trimmedDuration > 0 else {
                    return accumulatedPixel
                }

                let pxPerSecond = effective / clip.trimmedDuration
                return accumulatedPixel + CGFloat(timeInClip) * pxPerSecond
            }

            accumulatedTime = clipEndTime
            accumulatedPixel += effectiveWidth(for: index)
        }

        return accumulatedPixel
    }

    /// pixel offset → playTime(초)
    func playTime(for pixelOffset: CGFloat) -> Double {
        guard pixelOffset >= 0 else { return 0 }

        // 클립이 없으면 0 반환
        guard !editableClips.isEmpty else { return 0 }

        var accumulatedTime: Double = 0
        var accumulatedPixel: CGFloat = 0

        for (index, clip) in editableClips.enumerated() {
            let effective = effectiveWidth(for: index)
            let clipEndPixel = accumulatedPixel + effective

            if pixelOffset <= clipEndPixel {
                let pixelInClip = pixelOffset - accumulatedPixel

                // division by zero 방지
                guard clip.trimmedDuration > 0 else {
                    return accumulatedTime
                }

                let pxPerSecond = effective / clip.trimmedDuration
                return accumulatedTime + Double(pixelInClip) / pxPerSecond
            }

            accumulatedTime += clip.trimmedDuration
            accumulatedPixel = clipEndPixel
        }

        return accumulatedTime
    }
}
