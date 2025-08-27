//
//  TempClipData.swift
//  Chalkak
//
//  Created by Youbin on 8/21/25.
//

import Foundation

struct TempClipData: Hashable {
    let url: URL
    let originalDuration: Double
    let startPoint: Double
    let endPoint: Double
    let tiltList: [TimeStampedTilt]
    
    // EditableClip으로 변환
    func toEditableClip() -> EditableClip {
        return EditableClip(
            id: UUID().uuidString,
            url: url,
            originalDuration: originalDuration,
            startPoint: startPoint,
            endPoint: endPoint,
            thumbnails: []
        )
    }
}
