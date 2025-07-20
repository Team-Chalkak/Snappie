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
        VStack(alignment: .center, spacing: 0) {

            //TODO: - 추후 구현 예정
            TrimmingTimeDisplayView()

            HStack(spacing: 15) {
                /// 재생/일시정지 버튼
                Button(action: {
                    editViewModel.togglePlayback()
                }) {
                    Image(editViewModel.isPlaying ? "pauseBtn" : "playBtn")
                        .resizable()
                        .frame(width: 36, height: 36)
                        .foregroundColor(.black)
                }

                /// 썸네일 + 트리밍 슬라이더
                TrimmingLineView(editViewModel: editViewModel, isDragging: $isDragging)
            }
            .frame(height: 128)
            .padding(.horizontal, 16)
            .background(.gray)
        }
    }
}
