//
//  Text + Ext.swift
//  Chalkak
//
//  Created by 석민솔 on 7/22/25.
//

import SwiftUI

extension Text {
    /**
     Snappie 스타일을 적용하여 폰트, 자간(tracking), 줄 간격(line spacing)을 설정합니다.
          
     - Parameter style: `.proBody1`, `.kronaLabel1` 등, 적용할 `SnappieFont.Style` 값입니다.
     
     이 메서드는 다음 속성들을 자동으로 적용합니다:
     - `font`: 시스템 또는 커스텀 폰트
     - `tracking`: Figma에서 정의된 자간 비율을 기반으로 계산된 값
     - `lineSpacing`: 해당 스타일의 줄 높이(line-height) 기준
          
     ## Example:
     ```swift
     Text("본문 텍스트입니다.\n줄 간격과 자간이 적용돼요.")
        .snappieStyle(.proBody1)
     ```
     */
    func snappieStyle(_ style: SnappieFont.Style) -> some View {
        self.font(SnappieFont.style(style))
            .tracking(style.spacing)
            .lineSpacing(style.lineHeight)
    }
}
