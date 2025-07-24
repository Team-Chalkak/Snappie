//
//  OverlayView.swift
//  Chalkak
//
//  Created by Youbin on 7/15/25.
//

import SwiftUI

/**
 OverlayView: 윤곽선 오버레이를 확인하고 다음 단계로 이동하는 뷰

 영상에서 추출된 윤곽선 오버레이 가이드를 사용자에게 시각적으로 확인시켜 주는 역할
 네비게이션 바를 포함하며, 확인 후 다음 뷰(가이드 적용 뷰)로 이동할 수 있음

 ## 주요 기능
 - 첫 프레임 + 윤곽선 오버레이 시각화
 - 뒤로가기 및 다음 버튼을 통한 뷰 전환
 - OverlayViewModel과 연동하여 오버레이 상태 관리
 
 ## 데이터 흐름
 - "뒤로" 버튼 선택 시: 오버레이 상태 초기화 (`dismissOverlay()`)
 - "다음" 버튼 선택 시:
     - `OverlayViewModel.makeGuide()`를 통해 Guide 객체 생성

 ## 호출 위치
 - ClipEditView → OverlayView로 이동
 - 호출 예시: 
 */
struct OverlayView: View {
    // 1. Input properties
    let clip: Clip

    // 2. State & ObservedObject
    @StateObject var overlayViewModel: OverlayViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToCameraView = false
    @EnvironmentObject private var coordinator: Coordinator
    @State private var guide: Guide?
    
    // 3. init
    init(clip: Clip) {
        self.clip = clip
        self._overlayViewModel = StateObject(wrappedValue: OverlayViewModel(clip: clip))
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 20, content: {
            if overlayViewModel.isOverlayReady {
                Spacer().frame(height: 1)
                
                Text("생성된 가이드를 확인해보세요")
                
                OverlayDisplayView(overlayViewModel: overlayViewModel)
                
                Spacer()
                
            } else {
                ProgressView("윤곽선 생성 중...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .foregroundStyle(.white)
                    .tint(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
            }
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
                    if let newGuide = overlayViewModel.makeGuide(clipID: clip.id) {
                        guide = newGuide
                        coordinator.push(.boundingBox(guide: newGuide))
                    } else {
                        print("❌ guide 생성 실패")
                    }
                }
            }
        }
        .onDisappear {
            overlayViewModel.dismissOverlay()
        }
    }
}
