//
//  NavigationEnums.swift
//  Chalkak
//
//  Created by 석민솔 on 7/25/25.
//

import Foundation

// 네비게이션용 커스텀 타입들
extension SnappieNavigationBar {
    /// 네비게이션바 왼쪽 버튼용 enum
    enum LeftButtonType {
        /// `<` 버튼  with action
        case backward(() -> Void)
        ///  `x`버튼  with action
        case dismiss(() -> Void)
    }

    /// 네비게이션바 오른쪽 버튼용 enum
    enum RightButtonType {
        case none
        case oneButton(ItemsForButton)
        case twoButton(primary: ItemsForButton, secondary: ItemsForButton)
    }

    /// 버튼을 위해 필요한 정보들
    struct ItemsForButton {
        enum Style {
            case text(String)
            case icon(Icon)
        }
        
        let style: Style
        let isEnabled: Bool
        let action: () -> Void
        
        init(
            label: String,
            isEnabled: Bool = true,
            action: @escaping () -> Void
        ) {
            self.style = .text(label)
            self.isEnabled = isEnabled
            self.action = action
        }
        
        init(
            icon: Icon,
            isEnabled: Bool = true,
            action: @escaping () -> Void
        ) {
            self.style = .icon(icon)
            self.isEnabled = isEnabled
            self.action = action
        }
    }
}
