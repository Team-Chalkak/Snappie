//
//  SnappieButtonStyle.swift
//  Chalkak
//
//  Created by 석민솔 on 7/24/25.
//

import SwiftUI

/// 디자인 시스템에 사용되는 커스텀 버튼 스타일입니다.
///
/// 이 스타일은 `ButtonStyler` 프로토콜을 준수하는 '스타일러'를 통해
/// 버튼의 구체적인 모양(패딩, 색상, 배경 등)을 결정합니다.
struct SnappieButtonStyle: ButtonStyle {
    let styler: ButtonStyler
    
    func makeBody(configuration: Configuration) -> some View {
        SnappieButtonView(
            configuration: configuration,
            styler: styler
        )
    }
    
    private struct SnappieButtonView: View {
        let configuration: ButtonStyle.Configuration
        let styler: ButtonStyler
        @Environment(\.isEnabled) private var isEnabled
                
        // 스타일러의 정의에 따라 패딩, 배경, 전경색 등 다양한 수정자를 적용하여 버튼의 최종 UI를 구성합니다.
        var body: some View {
            let isPressed = configuration.isPressed
            
            configuration.label
                .padding(styler.padding())
                .frame(height: styler.height(), alignment: .center)
                .background(styler.background(isPressed: isPressed, isEnabled: isEnabled))
                .foregroundColor(styler.foregroundColor(isPressed: isPressed, isEnabled: isEnabled))
                .animation(.easeInOut(duration: 0.15), value: isPressed)
                .animation(.easeInOut(duration: 0.15), value: isEnabled)
        }
    }
}
