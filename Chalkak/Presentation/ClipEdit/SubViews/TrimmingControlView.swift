//
//  TrimmingControlView.swift
//  Chalkak
//
//  Created by Youbin on 7/15/25.
//

import SwiftUI

/// 트리밍 컨트롤 뷰(재생/일시정지 버튼 + 트리밍 라인)
struct TrimmingControlView: View {
    @ObservedObject var editViewModel: ClipEditViewModel
    @Binding var isDragging: Bool

    var body: some View {
        VStack(alignment: .center, spacing: 0) {

            // 📌 추후 구현 예정
            TrimmingTimeDisplayView()

            HStack(spacing: 15) {
                // ▶️ 재생/일시정지 버튼
                Button(action: {
                    editViewModel.togglePlayback()
                }) {
                    Image(editViewModel.isPlaying ? "pauseBtn" : "playBtn")
                        .resizable()
                        .frame(width: 36, height: 36)
                        .foregroundColor(.black)
                }

                // 🎞️ 썸네일 + 트리밍 슬라이더
                TrimmingLineView(editViewModel: editViewModel, isDragging: $isDragging)
            }
            .frame(height: 128)
            .padding(.horizontal, 16)
            .background(.gray)
        }
    }
}
