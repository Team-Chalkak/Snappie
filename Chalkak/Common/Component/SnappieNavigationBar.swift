//
//  SnappieNavigationBar.swift
//  Chalkak
//
//  Created by 석민솔 on 7/25/25.
//

import SwiftUI

/// 기본 네비게이션바 컴포넌트입니다.
struct SnappieNavigationBar: View {
    // MARK: input properties
    /// 네비게이션 타이틀입니다. 제목이 있는 경우 입력해주세요.
    ///
    /// 제목을 입력하지 않는 경우 기본값으로 없음 처리됩니다.
    var navigationTitle: String? = nil

    /// 좌측 버튼의 스타일입니다. 이전 또는 X를 enum타입으로 입력해주세요
    let leftButtonType: LeftButtonType

    /// 우측 버튼의 스타일입니다. 버튼이 없거나, 있다면 필요한 값들을 입력해주세요
    let rightButtonType: RightButtonType

    // MARK: body
    var body: some View {
        ZStack(alignment: .center) {
            // 버튼
            NavigationButtonHStack(
                leftButtonType: leftButtonType,
                rightButtonType: rightButtonType
            )

            // 제목
            if let navigationTitle {
                Text(navigationTitle)
                    .font(SnappieFont.style(.proLabel1))
                    .foregroundStyle(Color.matcha50)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

#Preview {
    ZStack {
        SnappieColor.darkHeavy

        VStack(spacing: 20) {
            // 이전(<) 버튼 & 우측 1개 버튼
            SnappieNavigationBar(
                leftButtonType: .backward {
                    // 뒤로가기 acion
                },
                rightButtonType: .oneButton(
                    .init(
                        label: "singleButton",
                        action: {}
                    )
                )
            )
            .background(
                // padding을 보여드리기 위한 bcg입니다. 기본적으로 가로 16, 세로 8 패딩이 적용되어 있습니다.
                Color.white
            )

            // dismiss(x) 버튼 & 우측 2개 버튼
            SnappieNavigationBar(
                leftButtonType: .dismiss {
                    // dismiss action
                },
                rightButtonType: .twoButton(
                    primary: .init(label: "firstButton") {},
                    secondary: .init(label: "sceondButton") {}
                )
            )

            // dismiss(x) 버튼 & title 있음 & 우측 버튼
            SnappieNavigationBar(
                navigationTitle: "title",
                leftButtonType: .dismiss {
                    // dismiss action
                },
                rightButtonType: .oneButton(
                    .init(label: "label") {}
                )
            )
        }
    }
}
