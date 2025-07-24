//
//  IconView.swift
//  Chalkak
//
//  Created by 석민솔 on 7/22/25.
//

import SwiftUI

/// 아이콘을 위한 공통 컴포넌트
struct IconView: View {
    // Input Properties
    let iconType: Icon
    let scale: IconScale

    // body
    var body: some View {
        Image(iconType.rawValue)
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .frame(width: scale.rawValue, height: scale.rawValue)
    }
}

#Preview {
    // 색상은 다른 UI 컴포넌트와 동일하게 foregroundStyle로 지정해서 사용하시면 됩니다.
    IconView(iconType: .flashOn, scale: .xlarge)
        .foregroundStyle(SnappieColor.labelPrimaryNormal)
        .background(Color.black)
    
    IconView(iconType: .timerOff, scale: .medium)
        .foregroundStyle(SnappieColor.containerFillNormal)
}
