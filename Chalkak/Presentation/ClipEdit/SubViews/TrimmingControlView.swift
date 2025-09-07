//
//  TrimmingControlView.swift
//  Chalkak
//
//  Created by Youbin on 7/15/25.
//

import SwiftUI

/**
 TrimmingControlView: 클립 트리밍을 위한 조작 요소들을 포함한 뷰.
 
 시간 정보 표시와 트리밍 라인(썸네일 타임라인 및 드래그 가능한 핸들)을 통해, 영상 트리밍에 필요한 다양한 조작을 수행할 수 있도록 도와주는 메인 뷰
 
 ## 구성 요소(서브뷰)
 - `TrimmingTimeDisplayView`: 현재 시간 / 전체 영상 길이 표시
 - `TrimmingLineView`: 썸네일 타임라인 및 핸들 드래그 기반의 구간 조절 슬라이더

 ## 호출 위치
 - `ClipEditView` 내에서 영상 클립의 트리밍 조작 섹션으로 사용됨
 - 호출 예시 : TrimmingControlView(editViewModel: editViewModel, isDragging: $isDragging)
 */
struct TrimmingControlView: View {
    @ObservedObject var editViewModel: ClipEditViewModel
    @Binding var isDragging: Bool

    var body: some View {
        VStack(alignment: .center, spacing: 8, content: {
            Divider()
                .foregroundStyle(Color.deepGreen50.opacity(0.1))
            
            TrimmingTimeDisplayView(editViewModel: editViewModel)
            
            TrimmingLineView(editViewModel: editViewModel, isDragging: $isDragging)
                .padding(.horizontal, 26)
            
        })
    }
}
