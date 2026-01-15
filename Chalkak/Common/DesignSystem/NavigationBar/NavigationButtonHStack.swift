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
                            size: .medium,
                            isActive: true
                        ),
                        action: action
                    )

                case .dismiss(let action):
                    SnappieButton(
                        .iconBackground(
                            icon: .dismiss,
                            size: .medium,
                            isActive: true
                        ),
                        action: action
                    )
                }

                Spacer()

                // right button(s)
                // Secondary (우측 왼쪽)
                if let secondary = secondaryRightButton {
                    rightButtonView(secondary, isPrimary: false)
                        .disabled(!secondary.isEnabled)
                        .opacity(secondary.isEnabled ? 1.0 : 0.4)
                }

                // Primary (우측 오른쪽)
                if let primary = primaryRightButton {
                    rightButtonView(primary, isPrimary: true)
                        .disabled(!primary.isEnabled)
                        .opacity(primary.isEnabled ? 1.0 : 0.4)
                }
            }
        }
        
        @ViewBuilder
        private func rightButtonView(
            _ item: ItemsForButton,
            isPrimary: Bool
        ) -> some View {
            switch item.style {
            case .text(let title):
                if isPrimary {
                    SnappieButton(
                        .solidPrimary(
                            title: title,
                            size: .medium
                        ),
                        action: item.action
                    )
                } else {
                    SnappieButton(
                        .solidSecondary(
                            contentType: .text(title),
                            size: .medium,
                            isOutlined: true
                        ),
                        action: item.action
                    )
                }

            case .icon(let icon):
                SnappieButton(
                    .iconBackground(
                        icon: icon,
                        size: .medium,
                        isActive: item.isEnabled
                    ),
                    action: item.action
                )
            }
        }

    }
}
