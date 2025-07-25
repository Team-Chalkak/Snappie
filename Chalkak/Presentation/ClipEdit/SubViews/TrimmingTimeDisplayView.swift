//
//  TrimmingTimeDisplayView.swift
//  Chalkak
//
//  Created by Youbin on 7/26/25.
//

import SwiftUI

/**
 TrimmingTimeDisplayView: 영상 시간 표시 뷰

 트리밍 UI 상단에 현재 영상 시점과 전체 영상 길이를 텍스트로 표시합니다.
 실제 시간 값은 향후 `editViewModel` 데이터를 활용하여 업데이트될 예정입니다.

 ## 호출 위치
 - `TrimmingControlView` 내 상단에 배치되어 사용됨
 - 호출 예시
    TrimmingTimeDisplayView(editViewModel: editViewModel)
 */
struct TrimmingTimeDisplayView: View {
    @ObservedObject var editViewModel: ClipEditViewModel
    
    var body: some View {
        HStack(content: {
            //TODO: 현재 영상 시간
            Text("00:00")
                .font(SnappieFont.style(.roundCaption1))
                .foregroundStyle(SnappieColor.primaryHeavy)
            
            Spacer()
            
            //TODO: 원본 영상 길이
            Text("00.15")
                .font(SnappieFont.style(.roundCaption1))
                .foregroundStyle(SnappieColor.primaryHeavy)
        })
        .padding(.horizontal, 24)
    }
}
