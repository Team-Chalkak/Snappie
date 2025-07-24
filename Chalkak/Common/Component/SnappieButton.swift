//
//  SnappieButton.swift
//  Chalkak
//
//  Created by 석민솔 on 7/23/25.
//

import SwiftUI

/**
 버튼 라우터(버튼 공장)
 
 공통 버튼 컴포넌트는 해당 뷰 구조체인 SnappieButton을 활용해서 만드시면 됩니다.
 
 ## 사용 예시
 ```swift
 // Icon With Text
 SnappieButton(.iconWithText(
     title: "Timer",
     icon: .timer5sec,
     isActive: isActive
 )) {
     isActive.toggle()
     print("Icon With Text Tapped")
 }
 
 // Solid Secondary Outlined (Text)
 SnappieButton(.solidSecondary(
     contentType: .text("Secondary Outlined"),
     size: .medium,
     isOutlined: true
 )) {
     print("Solid Secondary (Text) Tapped")
 }
 ```
 
 - disable은 기본 버튼처럼 disable modifier를 통해 스타일 적용이 가능합니다
 ```swift
 SnappieButton(.solidPrimary(
     title: "Primary Button",
     size: .large
 )) {
     print("Solid Primary Tapped")
 }
 .disabled(true)
 ```
 
 
 */
struct SnappieButton: View {
    let type: ButtonType
    let action: () -> Void
    
    init(_ type: ButtonType, action: @escaping () -> Void) {
        self.type = type
        self.action = action
    }
    
    var body: some View {
        switch type {
        case .solidPrimary(let title, let size):
            ButtonSolidPrimary(size: size, title: title, action: action)
            
        case .solidSecondary(let contentType, let size, let isOutlined):
            ButtonSolidSecondary(contentType: contentType, size: size, isOutlined: isOutlined, action: action)
            
        case .iconNormal(let icon, let size):
            ButtonIconNormal(icon: icon, size: size, action: action)
            
        case .iconSolid(let icon, let size):
            ButtonIconSolid(icon: icon, size: size, action: action)
            
        case .iconBackground(let icon, let size):
            ButtonIconBackground(icon: icon, size: size, action: action)
            
        case .iconWithText(let title, let icon, let isActive):
            ButtonIconWithText(title: title, icon: icon, isActive: isActive, action: action)
            
        case .glassPill(let contentType, let isActive):
            ButtonGlassPill(contentType: contentType, isActive: isActive, action: action)
            
        case .glassEllipse(let contentType, let isActive):
            ButtonGlassEllipse(contentType: contentType, isActive: isActive, action: action)
        }
    }
}
