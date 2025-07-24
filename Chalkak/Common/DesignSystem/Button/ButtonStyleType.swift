//
//  ButtonStyleType.swift
//  Chalkak
//
//  Created by 석민솔 on 7/22/25.
//

import SwiftUI

// MARK: ENUM 정의
/// 버튼의 큰 분류
enum ButtonCategory {
    case solid
    case icon
    case glass
}

/// 버튼 하위 타입 분류
enum ButtonType{
    case solidPrimary(title: String, size: ButtonSizeType)
    case solidSecondary(contentType: ButtonContentType, size: ButtonSizeType, isOutlined: Bool)
    
    case iconNormal(icon: Icon, size: ButtonSizeType)
    case iconSolid(icon: Icon, size: ButtonSizeType)
    case iconBackground(icon: Icon, size: ButtonSizeType)
    case iconWithText(title: String, icon: Icon, isActive: Bool)
    
    case glassPill(contentType: ButtonContentType, isActive: Bool)
    case glassEllipse(contentType: ButtonContentType, isActive: Bool)
    
    var bigCategory: ButtonCategory {
        switch self {
        case .solidPrimary, .solidSecondary: .solid
        case .iconNormal,.iconSolid, .iconBackground, .iconWithText: .icon
        case .glassPill, .glassEllipse: .glass
        }
    }
}


// MARK: 버튼 정보 공통 타입
/// 버튼 크기 종류
enum ButtonSizeType {
    case large
    case medium
}
/// 버튼 내부 콘텐츠 종류
enum ButtonContentType {
    /// Text가 버튼의 label로 들어오는 경우
    case text(String)
    /// 커스텀 아이콘 이미지가 label로 들어오는 경우
    case icon(Icon)
}
