//
//  OverlayView.swift
//  Chalkak
//
//  Created by Youbin on 7/15/25.
//

import SwiftUI

struct OverlayView: View {
    @ObservedObject var viewModel: ClipEditViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 30, content: {
                
                Spacer().frame(height: 0)

                Text("생성된 가이드를 확인해보세요")

                ZStack {
                    // ✅ 배경: 첫 프레임 (그대로)
                    if let firstFrame = viewModel.extractor.extractedImage {
                        Image(uiImage: firstFrame)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 296, height: 526)
                    }

                    // ✅ 오버레이: 윤곽선
                    if let outline = viewModel.overlayManager.outlineImage {
                        Image(uiImage: outline)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 296, height: 526)
                    } else {
                        Text("윤곽선 이미지 없음")
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
            })
            .navigationBarBackButtonHidden()
            .navigationTitle("가이드 확인")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("뒤로") {
                        viewModel.dismissOverlay()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("다음") {
                        viewModel.createGuideForLog()
                        // TODO: - 저장 후 다음 화면으로 넘어가는 로직 필요
                    }
                }
            }
            
        }
    }
}
