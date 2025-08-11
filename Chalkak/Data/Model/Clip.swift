//
//  Clip.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

import Foundation
import SwiftData

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
        
    /// 트리밍된 시간을 계산한 정보.
    var currentTrimmedDuration: Double {
        max(0, endPoint - startPoint)
    }
    
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
        tiltList: [TimeStampedTilt] = []
    ) {
        self.id = id
        self.videoURL = videoURL
        self.originalDuration = originalDuration
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.createdAt = createdAt
        self.tiltList = tiltList
    }
}
