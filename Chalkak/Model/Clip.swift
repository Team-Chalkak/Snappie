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
    var tiltListJSON: String
    var heightListJSON: String

    init(
        id: String = UUID().uuidString,
        videoData: Data,
        startPoint: Double = 0,
        endPoint: Double,
        createdAt: Date = .now,
        tiltList: [(Date, Tilt)] = [],
        heightList: [(Date, Float)] = []
    ) {
        self.id = id
        self.videoData = videoData
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.createdAt = createdAt
        self.tiltListJSON = Self.encodeTiltList(tiltList)
        self.heightListJSON = Self.encodeHeightList(heightList)
    }

    // MARK: - Encode/Decode helpers
    static func encodeTiltList(_ list: [(Date, Tilt)]) -> String {
        let codableList = list.map { TimeStampedTilt(time: $0.0, tilt: $0.1) }
        let data = try? JSONEncoder().encode(codableList)
        return String(data: data ?? Data(), encoding: .utf8) ?? "[]"
    }

    static func encodeHeightList(_ list: [(Date, Float)]) -> String {
        let codableList = list.map { TimeStampedHeight(time: $0.0, height: $0.1) }
        let data = try? JSONEncoder().encode(codableList)
        return String(data: data ?? Data(), encoding: .utf8) ?? "[]"
    }
}

// MARK: - Codable helpers
private struct TimeStampedTilt: Codable {
    let time: Date
    let tilt: Tilt
}

private struct TimeStampedHeight: Codable {
    let time: Date
    let height: Float
}
