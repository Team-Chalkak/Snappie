//
//  SchemaV2.swift
//  Chalkak
//
//  Created by 배현진 on 10/4/25.
//

import Foundation
import SwiftData
import UIKit

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Clip.self, Guide.self, Project.self, CameraSetting.self]
    }

    // MARK: - Clip
    /// 영상 데이터와 관련된 메타 정보를 저장하는 클립 모델입니다.
    @Model
    class Clip {
        /// 클립의 고유 식별자.
        @Attribute(.unique) var id: String
        
        /// 영상의 바이너리 데이터.
        var videoURL: URL
        
        /// 원본 영상의 총 길이 (초 단위). 클립 생성 시 한 번만 계산하여 저장됩니다.
        var originalDuration: Double
        
        /// 트리밍하여 사용할 영상 구간의 시작 시점. (초 단위)
        var startPoint: Double
        
        /// 트리밍하여 사용할 영상 구간의 종료 시점. (초 단위)
        var endPoint: Double
        
        /// 클립이 생성된 시간.
        var createdAt: Date
        
        /// 시간별로 기록된 카메라 기울기 정보.
        var tiltList: [TimeStampedTilt]
        
        /// 순서 보장을 위한 정보.
        var order: Int = 0
            
        /// 트리밍된 시간을 계산한 정보.
        var currentTrimmedDuration: Double {
            max(0, endPoint - startPoint)
        }
        
        /// 임시 클립 여부 (temp 프로젝트 내의 클립은 true)
        var isTemp: Bool = false
        
        /// temp 클립이 참조하는 원본 클립의 ID
        /// 새로 추가된 클립의 경우 nil
        var originalClipID: String? = nil
        
        
        /// 새로운 Clip 인스턴스를 초기화합니다.
        /// - Parameters:
        ///   - id: 클립의 고유 ID (기본값은 UUID).
        ///   - videoData: 영상의 데이터.
        ///   - originalDuration: 원본 영상의 총 길이.
        ///   - startPoint: 시작 시점 (초 단위).
        ///   - endPoint: 종료 시점 (초 단위).
        ///   - createdAt: 생성일자 (기본값은 현재 시각).
        ///   - tiltList: 시간별 기울기 정보 목록.
        ///   - heightList: 시간별 높이 정보 목록.
        init(
            id: String = UUID().uuidString,
            videoURL: URL,
            originalDuration: Double,
            startPoint: Double = 0,
            endPoint: Double,
            createdAt: Date = .now,
            tiltList: [TimeStampedTilt] = [],
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
            self.isTemp = isTemp
            self.originalClipID = originalClipID
        }
    }
    
    // MARK: - Guide
    /// 클립 간의 구도 일치를 위한 가이드 정보를 담는 모델입니다.
    @Model
    class Guide: Identifiable {
        /// 가이드가 연결된 클립의 ID.
        @Attribute(.unique) var clipID: String
        
        /// 여러 명의 바운딩 박스 정보 (위치 + 크기)
        var boundingBoxes: [BoundingBoxInfo]
        
        /// 카메라 기울기.
        var cameraTilt: Tilt
        
        /// 가이드 생성 당시 프리뷰가 미러였는지 (V2에서 새로 추가)
        var wasMirroredAtCapture: Bool = false
            
        /// 가이드가 생성된 시점.
        var createdAt: Date
        
        /// 윤곽선 이미지의 바이너리 데이터.
        var outlineImageData: Data

        /// 윤곽선 이미지 데이터에서 생성된 UIImage.
        var outlineImage: UIImage? {
            UIImage(data: outlineImageData)
        }

        /// 새로운 `Guide` 인스턴스를 초기화합니다.
        /// - Parameters:
        ///   - clipID: 연결된 클립의 ID.
        ///   - bBoxPosition: 바운딩 박스의 위치.
        ///   - bBoxScale: 바운딩 박스의 크기.
        ///   - outlineImage: 윤곽선 이미지.
        ///   - cameraTilt: 촬영 당시의 카메라 기울기.
        ///   - isFrontPosition: 촬영 당시 카메라의 전면 모드 여부 (기본값 false).
        ///   - createdAt: 생성 시각 (기본값은 현재 시간).
        init(
            clipID: String,
            boundingBoxes: [BoundingBoxInfo],
            outlineImage: UIImage,
            cameraTilt: Tilt,
            wasMirroredAtCapture: Bool = false, // 마이그레이션을 위해 기본값 추가
            createdAt: Date = .now
        ) {
            self.clipID = clipID
            self.boundingBoxes = boundingBoxes
            self.cameraTilt = cameraTilt
            self.wasMirroredAtCapture = wasMirroredAtCapture
            self.createdAt = createdAt
            self.outlineImageData = outlineImage.pngData() ?? Data()
        }
    }

    // MARK: - Project
    /// 하나의 영상으로 만들기 위한 클립 목록과 가이드를 포함하는 프로젝트 모델입니다.
    @Model
    class Project: Identifiable {
        /// 프로젝트의 고유 식별자.
        @Attribute(.unique) var id: String
        
        /// 프로젝트에 연결된 가이드.
        /// 프로젝트가 삭제되면 함께 삭제됩니다.
        @Relationship(deleteRule: .cascade) var guide: Guide
        
        /// 프로젝트를 구성하는 클립 목록.
        /// 프로젝트가 삭제되면 함께 삭제됩니다.
        @Relationship(deleteRule: .cascade) var clipList: [Clip]
        
        /// 프로젝트에서 사용된 카메라 설정 정보.
        /// 프로젝트가 삭제되면 함께 삭제됩니다.
        @Relationship(deleteRule: .cascade) var cameraSetting: CameraSetting?
        
        /// 프로젝트 제목
        var title: String
        
        /// 첫번째 클립의 트리밍된 클립 길이.
        /// 이후 클립 편집 시 초기값으로 사용.
        var referenceDuration: Double?
        
        /// 유저가 새 프로젝트를 확인했는지 여부
        var isChecked: Bool = false
        
        /// 프로젝트 커버 이미지 - 첫번째 영상 첫번째 프레임으로 설정
        var coverImage: Data?
        
        /// 프로젝트 생성 시간
        var createdAt: Date
        
        /// 전체 프로젝트 영상 길이
        var totalDuration: Double {
            clipList.reduce(0) { $0 + $1.currentTrimmedDuration }
        }
        
        /// 임시 프로젝트 여부 (편집 중인 프로젝트 = true)
        var isTemp: Bool = false
        
        /// temp 프로젝트가 참조하는 원본 프로젝트의 ID
        /// temp가 아닌 경우 nil
        var originalID: String? = nil
        
        
        /// 새로운 `Project` 인스턴스를 초기화합니다.
        /// - Parameters:
        ///   - id: 고유 식별자 (기본값은 자동 생성된 UUID).
        ///   - guide: 연결할 가이드.
        ///   - clipList: 포함할 클립 목록.
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
    
    // MARK: - CameraSetting
    /// 영상 데이터와 관련된 메타 정보를 저장하는 클립 모델입니다.
    @Model
    class CameraSetting {
        /// 프로젝트 카메라 설정의 고유 식별자.
        @Attribute(.unique) var id: String
        
        /// 카메라의 줌 정도
        var zoomScale: CGFloat
        
        /// 카메라의 그리드 기능 적용 여부
        var isGridEnabled: Bool
        
        /// 카메라의 전면 모드 여부
        var isFrontPosition: Bool
        
        /// 카메라의 타이머 적용 시간 (적용 안된 경우가 0초)
        var timerSecond: Int
        
        /// 새로운 Clip 인스턴스를 초기화합니다.
        /// - Parameters:
        ///   - id: 카메라 기본 설정의 고유 ID (기본값은 UUID).
        ///   - zoomScale: 카메라의 줌 정도.
        ///   - isGridEnabled: 카메라의 그리드 기능 적용 여부.
        ///   - isFrontPosition: 카메라의 전면 모드 여부.
        ///   - timerSecond: 카메라의 타이머 적용 시간.
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
}
