//
//  AppStorageKey.swift
//  Chalkak
//
//  Created by 배현진 on 7/21/25.
//

enum UserDefaultKey {
    // CameraSetting
    static let isGridOn = "isGridOn"
    static let zoomScale = "zoomScale"
    static let timerSecond = "timerSecond"
    static let isFrontPosition = "isFrontPosition"
    static let cameraPosition = "cameraPosition"
  
    // Onboarding Key
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    
    // Current Project ID
    static let currentProjectID = "currentProjectID"
    
    // 프로젝트 편집뷰에서 별도의 추가 촬영인경우
    static let isAppendingShoot = "isAppendingShoot"
}
