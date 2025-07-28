//
//  SnappieFont.swift
//  Chalkak
//
//  Created by 석민솔 on 7/21/25.
//

import SwiftUI

/**
 프로젝트에서 사용할 폰트 시스템
 
 - Text extension의 snappieStyle 함수에서 내부적으로 해당 enum이 활용됩니다.
 ## 사용 예시
 ### 기본 사용
 ```swift
 Text("Dynamic Font")
     .font(SnappieFont.style(.proBody1))
 ```
 
 ### 크기 다르게 쓰고 싶을 때
 ```swift
 Text("Dynamic Font")
     .font(SnappieFont.style(.proBody1, size: 15))
 ```

 */
enum SnappieFont {
    /// 폰트 및 기본 Font 생성 시 필요한 스타일 적용
    static func style(_ style: Style) -> Font {
        switch style.fontName {
        case .kronaOne:
            Font.custom(
                style.fontName.rawValue,
                size: style.defaultSize
            )
        case .sfPro:
            Font.system(
                size: style.defaultSize,
                weight: style.weight,
                design: .default
            )
        case .sfProRounded:
            Font.system(
                size: style.defaultSize,
                weight: style.weight,
                design: .rounded
            )
        }
    }

    enum FontType: String {
        case sfPro
        case sfProRounded
        case kronaOne = "KronaOne-Regular"
    }
    
    // TODO: 폰트 시스템에 따라 추가 예정(ssol)
    enum Style {
        case proBody1
        case proLabel1
        case proLabel2
        case proLabel3
        case proCaption1
        
        case roundCaption1
        case roundCaption2
        
        case kronaLabel1
        case kronaCaption1
        case kronaExtra
        
        var fontName: FontType {
            switch self {
            case .proBody1, .proLabel1, .proLabel2, .proLabel3, .proCaption1:
                    .sfPro
                
            case .roundCaption1, .roundCaption2:
                    .sfProRounded
                
            case .kronaLabel1, .kronaCaption1, .kronaExtra:
                    .kronaOne
            }
        }
        
        var defaultSize: CGFloat {
            switch self {
            case .proBody1:
                16
            case .proLabel1:
                16
            case .proLabel2:
                14
            case .proLabel3:
                14
            case .proCaption1:
                14
                
            case .roundCaption1:
                12
            case .roundCaption2:
                10
                
            case .kronaLabel1:
                14
            case .kronaCaption1:
                6
            case .kronaExtra:
                164
            }
        }
        
        var weight: Font.Weight {
            switch self {
            case .proBody1:
                    .regular
            case .proLabel1:
                    .semibold
            case .proLabel2:
                    .semibold
            case .proLabel3:
                    .semibold
            case .proCaption1:
                    .regular
            case .roundCaption1:
                    .regular
            case .roundCaption2:
                    .regular
                
            case .kronaLabel1:
                    .regular
            case .kronaCaption1:
                    .regular
            case .kronaExtra:
                    .regular
            }
        }
        
        var lineHeight: CGFloat {
            switch self {
            case .proBody1: 4
            default: 0
            }
        }
        
        var spacing: CGFloat {
            switch self {
            case .proBody1:
                self.getSpacing(scale: -1.2)
            case .proLabel1:
                self.getSpacing(scale: -2)
            case .proLabel2:
                self.getSpacing(scale: -2)
            case .proLabel3:
                self.getSpacing(scale: -2)
            case .proCaption1:
                self.getSpacing(scale: -1.2)

            case .roundCaption1:
                self.getSpacing(scale: -1.2)
            case .roundCaption2:
                self.getSpacing(scale: -2)
                
            case .kronaLabel1:
                self.getSpacing(scale: -2)
            case .kronaCaption1:
                self.getSpacing(scale: -2)
            case .kronaExtra:
                0
            }
        }
        
        private func getSpacing(scale: CGFloat) -> CGFloat {
            return self.defaultSize * (scale / 100)
        }
    }
}
