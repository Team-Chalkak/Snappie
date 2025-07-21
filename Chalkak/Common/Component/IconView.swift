//
//  IconView.swift
//  Chalkak
//
//  Created by 석민솔 on 7/22/25.
//

import SwiftUI

/// 아이콘을 위한 공통 컴포넌트
struct IconView: View {
    // MARK: Input Properties
    let iconType: Icon
    let scale: IconScale
    var color: Color = SnappieColor.labelPrimaryNormal

    // MARK: body
    var body: some View {
        Image(iconType.rawValue)
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(color)
            .frame(width: scale.rawValue, height: scale.rawValue)
    }
}

#Preview {
    // 색상 없이 아이콘 종류와 크기만 지정한 경우, 기본값인 labelPrimaryNormal로 색상이 지정됩니다.
    IconView(iconType: .flashOn, scale: .xlarge)
        .background(Color.black)
    
    // 색상까지 지정한 경우, 지정한 색상의 아이콘으로 보여집니다.
    IconView(iconType: .timerOff, scale: .medium, color: SnappieColor.labelDarkInactive)
}
