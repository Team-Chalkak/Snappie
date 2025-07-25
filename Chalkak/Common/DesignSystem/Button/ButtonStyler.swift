//
//  ButtonStyler.swift
//  Chalkak
//
//  Created by 석민솔 on 7/23/25.
//

import SwiftUI

/// 버튼 스타일 프로토콜
///
/// - 버튼스타일에 적용시키기 위해 필요한 공통값
protocol ButtonStyler {
    func height() -> CGFloat
    func padding() -> EdgeInsets
    func background(isPressed: Bool, isEnabled: Bool) -> AnyView
    func foregroundColor(isPressed: Bool, isEnabled: Bool) -> Color
}

/// 버튼 크기 공통 관리용 height 상수
struct ButtonSizeConstant {
    static let heightLarge: CGFloat = 48
    static let heightMedium: CGFloat = 40
    static let heightSmall: CGFloat = 32
    static let heightMini: CGFloat = 26
}
