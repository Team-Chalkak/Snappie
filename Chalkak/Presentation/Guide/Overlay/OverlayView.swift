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
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToCameraView = false

    let clipID: String
    @State private var guide: Guide?
    
    var body: some View {
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
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("다음") {
                    /// 가이드 객체 생성
                    if let newGuide = overlayViewModel.makeGuide(clipID: clipID) {
                        guide = newGuide
                        navigateToCameraView = true
                    } else {
                        print("❌ guide 생성 실패")
                    }
                }
            }
        }
//        .navigationDestination(isPresented: $navigateToCameraView) {
//            if let guide = guide {
//                BoundingBoxView(guide: guide)
//            }
//        }
        // TODO: - 네비게이션 문제 발생 -> path 관리 방식으로 변경 (Berry)
        .onDisappear {
            overlayViewModel.dismissOverlay()
        }
    }
}
