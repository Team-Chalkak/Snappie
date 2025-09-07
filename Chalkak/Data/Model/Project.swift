//
//  Project.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

import Foundation
import SwiftData

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
