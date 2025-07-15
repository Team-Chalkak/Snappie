//
//  OverlayView.swift
//  Chalkak
//
//  Created by Youbin on 7/15/25.
//

import SwiftUI

/// 오버레이 확인뷰 + 네비게이션바
struct OverlayView: View {
    @ObservedObject var overlayViewModel: OverlayViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 20, content: {
                
                Spacer().frame(height: 1)

                Text("생성된 가이드를 확인해보세요")

                OverlayDisplayView(overlayViewModel: overlayViewModel)
                
                Spacer()
                
            })
            .navigationBarBackButtonHidden()
            .navigationTitle("가이드 확인")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("뒤로") {
                        overlayViewModel.dismissOverlay()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("다음") {
                        overlayViewModel.createGuideForLog()
                        // TODO: - 저장 후 다음 화면으로 넘어가는 로직 필요
                    }
                }
            }
            
        }
    }
}
