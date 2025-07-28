//
//  ButtonIcon.swift
//  Chalkak
//
//  Created by 석민솔 on 7/24/25.
//

import SwiftUI

// Icon 버튼 컴포넌트 4종을 위한 파일입니다
// SnappieButton 컴포넌트 내부에서만 사용되는 서브 뷰입니다. 외부에서 직접 호출할 일은 거의 없습니다.
struct ButtonIconNormal: View {
    // input properties
    let icon: Icon
    let size: ButtonSizeType
    let action: () -> Void
    
    // styler propety
    let styler: IconNormalStyler
    
    // init
    init(icon: Icon,
         size: ButtonSizeType,
         action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.action = action
        self.styler = IconNormalStyler(size: size)
    }
    // body
    var body: some View {
        Button (action: action) {
            IconView(
                iconType: icon,
                scale: styler.iconScale()
            )
        }
        .buttonStyle(SnappieButtonStyle(styler: styler))
    }
}

struct ButtonIconSolid: View {
    // input properties
    let icon: Icon
    let size: ButtonSizeType
    let action: () -> Void
    
    // styler propety
    let styler: IconSolidStyler
    
    // init
    init(icon: Icon,
         size: ButtonSizeType,
         action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.action = action
        self.styler = IconSolidStyler(size: size)
    }
    // body
    var body: some View {
        Button (action: action) {
            IconView(
                iconType: icon,
                scale: styler.iconScale()
            )
        }
        .buttonStyle(SnappieButtonStyle(styler: styler))
    }
}

struct ButtonIconBackground: View {
    // input properties
    let icon: Icon
    let size: ButtonSizeType
    let action: () -> Void
    
    // styler propety
    let styler: IconBackgroundStyler
    
    // init
    init(icon: Icon,
         size: ButtonSizeType,
         action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.action = action
        self.styler = IconBackgroundStyler(size: size)
    }
    // body
    var body: some View {
        Button (action: action) {
            IconView(
                iconType: icon,
                scale: styler.iconScale()
            )
        }
        .buttonStyle(SnappieButtonStyle(styler: styler))
    }
}

struct ButtonIconWithText: View {
    // input properties
    let title: String
    let icon: Icon
    let isActive: Bool
    let action: () -> Void
    
    // styler propety
    let styler: IconWithTextStyler
    
    // init
    init(title: String,
         icon: Icon,
         isActive: Bool,
         action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isActive = isActive
        self.action = action
        self.styler = IconWithTextStyler(isActive: isActive)
    }
    
    // body
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                IconView(
                    iconType: icon,
                    scale: styler.iconScale()
                )
                
                Text(title)
                    .font(SnappieFont.style(styler.fontStyle()))
            }
        }
        .frame(width: styler.height(), height: styler.height())
        .buttonStyle(SnappieButtonStyle(styler: styler))
    }
}


#Preview {
    ZStack {
        SnappieColor.primaryHeavy
        
        VStack {
            SnappieButton(.iconNormal(
                icon: .flashOn,
                size: .large
            )) {
                print("iconNormal button tapped")
            }
            
            SnappieButton(.iconSolid(
                icon: .flashOn,
                size: .large
            )) {
                print("iconNormal button tapped")
            }
            
            SnappieButton(.iconBackground(
                icon: .flashOn,
                size: .large
            )) {
                print("iconNormal button tapped")
            }
            
            SnappieButton(.iconWithText(title: "Timer", icon: .timer3sec, isActive: true)) {
                print("iconWithText button tapped")
            }
        }
    }
}
