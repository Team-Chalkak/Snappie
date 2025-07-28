//
//  OverlayDisplayView.swift
//  Chalkak
//
//  Created by Youbin on 7/15/25.
//

import SwiftUI

/**
 OverlayDisplayView: 윤곽선 오버레이 시각화 전용 뷰

 추출된 첫 프레임 이미지와 outline 이미지를 겹쳐 보여주는 UI 컴포넌트.

 ## 주요 기능
 - 배경 이미지: 영상의 첫 번째 프레임
 - 오버레이 이미지: 윤곽선 이미지
 - 윤곽선이 없는 경우 대체 텍스트 출력

 ## 호출 위치
 - OverlayView 내부에서 사용
 - 호출 예시: `OverlayDisplayView(overlayViewModel: overlayViewModel)`
 */
struct OverlayDisplayView: View {
    // 1. Input
    @ObservedObject var overlayViewModel: OverlayViewModel

    var body: some View {
        ZStack {
            /// ✅ 배경: 첫 프레임
            if let firstFrame = overlayViewModel.extractor.extractedImage {
                Image(uiImage: firstFrame)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            /// ✅ 오버레이: 윤곽선
            if let outline = overlayViewModel.overlayManager.outlineImage {
                Image(uiImage: outline)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Text("윤곽선 이미지 없음")
                    .foregroundColor(.gray)
            }
        }
    }
}

private extension OverlayDisplayView {
    enum Layout {
        static let overlayWidth: CGFloat = 296
        static let overlayHeight: CGFloat = 526
    }
}
