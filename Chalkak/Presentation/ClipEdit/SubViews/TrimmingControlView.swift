//
//  TrimmingControlView.swift
//  Chalkak
//
//  Created by Youbin on 7/15/25.
//

import SwiftUI

/**
 TrimmingControlView: 영상 트리밍 조작 뷰

 영상 트리밍을 위한 조작 요소들을 포함한 뷰.
 재생/일시정지 버튼과 썸네일 기반 트리밍 UI(`TrimmingLineView`)를 보여준다다.

 ## 주요 기능
 - 영상 재생 및 일시정지 버튼
 - 하위 뷰로 트리밍 슬라이더(`TrimmingLineView`) 호출

 ## 호출 위치
 -  ClipEditView 내에서 클립 재생/편집 UI로 사용됨
 - 호출 예시 : TrimmingControlView(editViewModel: editViewModel, isDragging: $isDragging)
 
 ## 서브뷰
 - TrimmingTimeDisplayView : 트리밍 핸들 시간 표시용 뷰(향후 구현 예정)
 - TrimmingLineView: 트리밍 타임라인과 좌우 핸들 조작이 가능한 슬라이더 뷰 
 */
struct TrimmingControlView: View {
    @ObservedObject var editViewModel: ClipEditViewModel
    @Binding var isDragging: Bool

    var body: some View {
        VStack(alignment: .center, spacing: 8, content: {
            Divider()
            
            HStack(content: {
                //TODO: 현재 영상 시간
                Text("00:00")
                
                Spacer()
                
                //TODO: 원본 영상 길이
                Text("00.15")
            })
            .padding(.horizontal, 24)
            
            TrimmingLineView(editViewModel: editViewModel, isDragging: $isDragging)
                .padding(.horizontal, 26)
            
        })
    }
}
