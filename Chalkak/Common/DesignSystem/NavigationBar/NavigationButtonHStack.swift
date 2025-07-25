//
//  NavigationButtonHStack.swift
//  Chalkak
//
//  Created by 석민솔 on 7/25/25.
//

import SwiftUI

extension SnappieNavigationBar {

    /// 네비게이션용 좌우측 버튼(들)이 분기처리되어있는 HStack입니다.
    struct NavigationButtonHStack: View {
        // input properties
        let leftButtonType: LeftButtonType
        let rightButtonType: RightButtonType

        // computed properties
        var primaryRightButton: ItemsForButton? {
            switch rightButtonType {
            case .none:
                nil
            case .oneButton(let button):
                button
            case .twoButton(let primaryButton, _):
                primaryButton
            }
        }

        var secondaryRightButton: ItemsForButton? {
            switch rightButtonType {
            case .twoButton(_, let secondaryButton):
                secondaryButton
            default: nil
            }
        }

        // body
        var body: some View {
            HStack {
                // left button
                switch leftButtonType {
                case .backward(let action):
                    SnappieButton(
                        .iconBackground(
                            icon: .chevronBackward,
                            size: .medium
                        ),
                        action: action
                    )

                case .dismiss(let action):
                    SnappieButton(
                        .iconBackground(
                            icon: .dismiss,
                            size: .medium
                        ),
                        action: action
                    )
                }

                Spacer()

                // (right button(s))
                if let secondaryRightButton {
                    SnappieButton(
                        .solidSecondary(
                            contentType: .text(secondaryRightButton.label),
                            size: .medium,
                            isOutlined: true
                        ),
                        action: secondaryRightButton.action
                    )
                }

                if let primaryRightButton {
                    SnappieButton(
                        .solidPrimary(
                            title: primaryRightButton.label,
                            size: .medium
                        ),
                        action: primaryRightButton.action
                    )
                }
            }
        }
    }

}
