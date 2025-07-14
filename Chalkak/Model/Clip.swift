//
//  Clip.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

import Foundation
import SwiftData

@Model
class Clip {
    @Attribute(.unique) var id: String
    var videoData: Data
    var startPoint: Double
    var endPoint: Double
    var createdAt: Date
    var tiltList: [TimeStampedTilt]
    var heightList: [TimeStampedHeight]

    init(
        id: String = UUID().uuidString,
        videoData: Data,
        startPoint: Double = 0,
        endPoint: Double,
        createdAt: Date = .now,
        tiltList: [TimeStampedTilt] = [],
        heightList: [TimeStampedHeight] = []
    ) {
        self.id = id
        self.videoData = videoData
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.createdAt = createdAt
        self.tiltList = tiltList
        self.heightList = heightList
    }
}

// MARK: - Codable helpers
struct TimeStampedTilt: Codable {
    let time: Int64
    let tilt: Tilt
}

struct TimeStampedHeight: Codable {
    let time: Int64
    let height: Float
}
