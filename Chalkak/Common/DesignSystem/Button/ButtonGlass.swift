//
//  ButtonGlass.swift
//  Chalkak
//
//  Created by 석민솔 on 7/24/25.
//

import SwiftUI

// Glass 버튼 컴포넌트 2종을 위한 파일입니다
// SnappieButton 컴포넌트 내부에서만 사용되는 서브 뷰입니다. 외부에서 직접 호출할 일은 거의 없습니다.
struct ButtonGlassPill: View {
    // input properties
    let contentType: ButtonContentType
    let isActive: Bool
    let action: () -> Void
    
    // styler propety
    let styler: GlassPillStyler
    
    // init
    init(contentType: ButtonContentType,
         isActive: Bool,
         action: @escaping () -> Void
    ) {
        self.contentType = contentType
        self.isActive = isActive
        self.action = action
        self.styler = GlassPillStyler(contentType: contentType, isActive: isActive)
    }
    
    // body
    var body: some View {
        Button (action: action) {
            Button(action: action) {
                switch contentType {
                case .icon(let icon):
                    IconView(
                        iconType: icon,
                        scale: styler.iconScale()
                    )
                case .text(let text):
                    Text(text)
                        .font(SnappieFont.style(styler.fontStyle()))
                }
            }
        }
        .buttonStyle(SnappieButtonStyle(styler: styler))
    }
}

struct ButtonGlassEllipse: View {
    // input properties
    let contentType: ButtonContentType
    let isActive: Bool
    let action: () -> Void
    
    // styler propety
    let styler: GlassEllipseStyler
    
    // init
    init(contentType: ButtonContentType,
         isActive: Bool,
         action: @escaping () -> Void
    ) {
        self.contentType = contentType
        self.isActive = isActive
        self.action = action
        self.styler = GlassEllipseStyler(contentType: contentType, isActive: isActive)
    }
    
    // body
    var body: some View {
        Button(action: action) {
            switch contentType {
            case .icon(let icon):
                IconView(
                iconType: icon,
                scale: styler.iconScale()
                )
            case .text(let text):
                Text(text)
                    .font(SnappieFont.style(styler.fontStyle()))
            }
        }
        .frame(width: styler.height(), alignment: .center)
        .buttonStyle(SnappieButtonStyle(styler: styler))
    }
}

#Preview {
    SnappieButton(.glassPill(
        contentType: .text("pill"),
        isActive: true)
    ) {
        print("glassPill button tapped")
    }
    
    SnappieButton(.glassEllipse(
        contentType: .text(".5"),
        isActive: false)
    ) {
        print("glassEllipse button tapped")
    }
}
