//
//  SnappieFont.swift
//  Chalkak
//
//  Created by 석민솔 on 7/21/25.
//

import SwiftUI

/**
 프로젝트에서 사용할 폰트 시스템
 
 ## 사용 예시
 ### 기본 사용
 ```swift
 Text("Dynamic Font")
     .font(SnappieFont.style(.recordTimer))
 ```
 
 ### 크기 다르게 쓰고 싶을 때
 ```swift
 Text("Dynamic Font")
     .font(SnappieFont.style(.recordTimer, size: 15))
 ```

 */
enum SnappieFont {
    static func style(_ style: Style, size: CGFloat? = nil) -> Font {
        Font.custom(style.fontName, size: size ?? style.defaultSize)
    }

    // TODO: 폰트 시스템이 나오면 추가 예정(ssol)
    enum Style {
        case recordTimer, cameraToolBar
        
        var fontName: String {
            switch self {
            case .recordTimer: return "KronaOne-Regular"
            case .cameraToolBar: return "KronaOne-Regular"
            }
        }
        
        var defaultSize: CGFloat {
            switch self {
            case .recordTimer: return 14
            case .cameraToolBar: return 8
            }
        }
    }
}
