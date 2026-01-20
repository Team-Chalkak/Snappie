//
//  SchemaV1.swift
//  Chalkak
//
//  Created by 배현진 on 10/4/25.
//

import Foundation
import SwiftData
import UIKit

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Clip.self, Guide.self, Project.self, CameraSetting.self]
    }
    
    // 배포되어 있던 시점의 Guide 정의
    @Model
    final class Guide: Identifiable {
        @Attribute(.unique) var clipID: String
        var boundingBoxes: [BoundingBoxInfo]
        var cameraTilt: Tilt
        var createdAt: Date
        var outlineImageData: Data

        // 계산 프로퍼티는 그대로 가능 (저장은 outlineImageData)
        var outlineImage: UIImage? { UIImage(data: outlineImageData) }

        init(
            clipID: String,
            boundingBoxes: [BoundingBoxInfo],
            outlineImage: UIImage,
            cameraTilt: Tilt,
            createdAt: Date = .now
        ) {
            self.clipID = clipID
            self.boundingBoxes = boundingBoxes
            self.cameraTilt = cameraTilt
            self.createdAt = createdAt
            self.outlineImageData = outlineImage.pngData() ?? Data()
        }
    }
    
    // 배포되어 있던 시점의 CameraSetting (isFrontPosition만 사용)
        @Model
        final class CameraSetting {
            @Attribute(.unique) var id: String
            var zoomScale: CGFloat
            var isGridEnabled: Bool
            var isFrontPosition: Bool
            var timerSecond: Int

            init(
                id: String = UUID().uuidString,
                zoomScale: CGFloat,
                isGridEnabled: Bool,
                isFrontPosition: Bool,
                timerSecond: Int = 0
            ) {
                self.id = id
                self.zoomScale = zoomScale
                self.isGridEnabled = isGridEnabled
                self.isFrontPosition = isFrontPosition
                self.timerSecond = timerSecond
            }
        }

        // 배포되어 있던 시점의 Project (Guide/CameraSetting 관계를 위함)
        @Model
        final class Project: Identifiable {
            @Attribute(.unique) var id: String

            // 관계 이름/방향이 실제 배포본과 같아야 합니다.
            @Relationship(deleteRule: .cascade) var guide: Guide
            @Relationship(deleteRule: .cascade) var clipList: [Clip]
            @Relationship(deleteRule: .cascade) var cameraSetting: CameraSetting?

            var title: String
            var referenceDuration: Double?
            var isChecked: Bool
            var coverImage: Data?
            var createdAt: Date
            var isTemp: Bool
            var originalID: String?

            init(
                id: String = UUID().uuidString,
                guide: Guide,
                clipList: [Clip] = [],
                cameraSetting: CameraSetting? = nil,
                title: String = "",
                referenceDuration: Double? = nil,
                isChecked: Bool = false,
                coverImage: Data? = nil,
                createdAt: Date = Date(),
                isTemp: Bool = false,
                originalID: String? = nil
            ) {
                self.id = id
                self.guide = guide
                self.clipList = clipList
                self.cameraSetting = cameraSetting
                self.title = title
                self.referenceDuration = referenceDuration
                self.isChecked = isChecked
                self.coverImage = coverImage
                self.createdAt = createdAt
                self.isTemp = isTemp
                self.originalID = originalID
            }
        }

        // 배포되어 있던 시점의 Clip – 마이그레이션에 직접 사용 x, Project.clipList 타입 일치용
        @Model
        final class Clip {
            @Attribute(.unique) var id: String
            var videoURL: URL
            var originalDuration: Double
            var startPoint: Double
            var endPoint: Double
            var createdAt: Date
            var tiltList: [TimeStampedTilt]
            var order: Int
            var isTemp: Bool
            var originalClipID: String?

            init(
                id: String = UUID().uuidString,
                videoURL: URL,
                originalDuration: Double,
                startPoint: Double = 0,
                endPoint: Double,
                createdAt: Date = .now,
                tiltList: [TimeStampedTilt] = [],
                order: Int = 0,
                isTemp: Bool = false,
                originalClipID: String? = nil
            ) {
                self.id = id
                self.videoURL = videoURL
                self.originalDuration = originalDuration
                self.startPoint = startPoint
                self.endPoint = endPoint
                self.createdAt = createdAt
                self.tiltList = tiltList
                self.order = order
                self.isTemp = isTemp
                self.originalClipID = originalClipID
            }
        }
}
