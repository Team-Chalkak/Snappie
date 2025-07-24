//
//  EditableClip.swift
//  Chalkak
//
//  Created by 배현진 on 7/24/25.
//

import Foundation

struct EditableClip: Identifiable, Equatable {
    let id: String
    let url: URL
    var startPoint: Double
    var endPoint: Double
    let originalDuration: Double
    let createdAt: Date

    var isTrimming: Bool = false

    var duration: Double {
        endPoint - startPoint
    }

    /// 타임라인 상에서의 위치 계산을 위한 프로퍼티 (총 영상 내 상대 위치 계산용)
    var timelineRange: ClosedRange<Double> {
        startPoint...endPoint
    }
}

extension EditableClip {
    init(from clip: Clip) {
        self.id = clip.id
        self.url = clip.videoURL
        self.startPoint = clip.startPoint
        self.endPoint = clip.endPoint
        self.originalDuration = clip.endPoint
        self.createdAt = clip.createdAt
    }
}
