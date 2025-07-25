//
//  ButtonSolid.swift
//  Chalkak
//
//  Created by 석민솔 on 7/22/25.
//

import SwiftUI

// Solid 버튼 컴포넌트 2종을 위한 파일입니다
// SnappieButton 컴포넌트 내부에서만 사용되는 서브 뷰입니다. 외부에서 직접 호출할 일은 거의 없습니다.
struct ButtonSolidPrimary: View {
    // input properties
    let size: ButtonSizeType
    let title: String
    let action: () -> Void
    
    // styler propety
    let styler: SolidPrimaryStyler
    
    // init
    init(
        size: ButtonSizeType,
        title: String,
        action: @escaping () -> Void
    ) {
        self.size = size
        self.title = title
        self.action = action
        self.styler = SolidPrimaryStyler(size: size)
    }
    
    // body
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SnappieFont.style(styler.fontStyle()))
        }
        .frame(height: size == .large ? 48 : 32)
        .buttonStyle(SnappieButtonStyle(styler: styler))
    }
}

struct ButtonSolidSecondary: View {
    // input properties
    let contentType: ButtonContentType
    let size: ButtonSizeType
    let isOutlined: Bool
    let action: () -> Void
    
    // styler propety
    let styler: SolidSecondaryStyler
    
    // init
    init(
        contentType: ButtonContentType,
        size: ButtonSizeType,
        isOutlined: Bool,
        action: @escaping () -> Void
    ) {
        self.contentType = contentType
        self.size = size
        self.isOutlined = isOutlined
        self.action = action
        self.styler = SolidSecondaryStyler(size: size, isOutlined: isOutlined, contentType: contentType)
    }
    
    // body
    var body: some View {
        Button(action: action) {
            switch contentType {
            case .text(let text):
                Text(text)
                    .font(SnappieFont.style(styler.fontStyle()))
            case .icon(let icon):
                IconView(iconType: icon, scale: styler.iconScale())
            }
        }
        .frame(height: size == .large ? 48 : 32)
        .buttonStyle(SnappieButtonStyle(styler: styler))
    }
}
