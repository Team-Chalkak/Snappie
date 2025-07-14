//
//  Clip.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

import Foundation
import SwiftData

@Model
/// A video clip containing video data and associated metadata.
class Clip {
    /// Unique identifier for the clip.
    @Attribute(.unique) var id: String
    
    /// Raw video data (e.g. from camera recording).
    var videoData: Data
    
    /// Start time of the relevant section (in seconds).
    var startPoint: Double
    
    /// End time of the relevant section (in seconds).
    var endPoint: Double
    
    /// Timestamp when the clip was created.
    var createdAt: Date
    
    /// Recorded camera tilt values with timestamps.
    var tiltList: [TimeStampedTilt]
    
    /// Recorded camera height values with timestamps.
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
