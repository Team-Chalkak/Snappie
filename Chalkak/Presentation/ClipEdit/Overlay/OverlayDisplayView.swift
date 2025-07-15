//
//  OverlayDisplayView.swift
//  Chalkak
//
//  Created by Youbin on 7/15/25.
//

import SwiftUI

/// 오버레이 확인뷰 이미지파트
struct OverlayDisplayView: View {
    @ObservedObject var overlayViewModel: OverlayViewModel
    
    var body: some View {
        ZStack {
            // ✅ 배경: 첫 프레임 (그대로)
            if let firstFrame = overlayViewModel.extractor.extractedImage {
                Image(uiImage: firstFrame)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 296, height: 526)
            }

            // ✅ 오버레이: 윤곽선
            if let outline = overlayViewModel.overlayManager.outlineImage {
                Image(uiImage: outline)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 296, height: 526)
            } else {
                Text("윤곽선 이미지 없음")
                    .foregroundColor(.gray)
            }
        }
    }
}
