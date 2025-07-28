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
    
    private var usingGuideText: String {
        overlayViewModel.isOverlayReady
            ? Context.buttonTitle
            : Context.buttonPlaceholder
    }
    
    // 3. init
    init(clip: Clip) {
        self.clip = clip
        self._overlayViewModel = StateObject(wrappedValue: OverlayViewModel(clip: clip))
    }
    
    var body: some View {
        ZStack {
            SnappieColor.darkHeavy.edgesIgnoringSafeArea(.all)
                
            if overlayViewModel.isOverlayReady {
                ContentView
                    .transition(.opacity)
            } else {
                // 대신 스켈레톤 뷰
                OverlaySkeletonView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.1), value: overlayViewModel.isOverlayReady)
        .onDisappear {
            overlayViewModel.dismissOverlay()
        }
    }
    
    private var ContentView: some View {
        VStack(alignment: .center) {
            SnappieNavigationBar(
                leftButtonType: .backward {
                    dismiss()
                },
                rightButtonType: .none
            )
            .padding(.top, Layout.navBarTopPadding)
            
            Spacer().frame(height: Layout.spacerHeight)
            
            Text(Context.guideGeneratedMessage)
                .snappieStyle(.proBody1)
                .foregroundStyle(SnappieColor.labelPrimaryNormal)
            
            OverlayDisplayView(overlayViewModel: overlayViewModel)
                .aspectRatio(
                    Layout.aspectRatioWidth / Layout.aspectRatioHeight,
                    contentMode: .fill)
                .padding(.horizontal, Layout.displayHorizontalPadding)
                .padding(.top, Layout.displayTopPadding)
                .padding(.bottom, Layout.displayBottomPadding)
            
            Spacer()
            
            Button(action: {
                if let newGuide = overlayViewModel.makeGuide(clipID: clip.id) {
                    guide = newGuide
                    coordinator.push(.boundingBox(guide: newGuide))
                }
            }) {
                Text(usingGuideText)
                    .snappieStyle(.proLabel1)
                    .padding(.horizontal, Layout.buttonHorizontalPadding)
            }
            .buttonStyle(SnappieButtonStyle(styler: SolidPrimaryStyler(size: .large)))
            .padding(.bottom, Layout.buttonBottomPadding)
        }
    }
}

private extension OverlayView {
    enum Context {
        static let guideGeneratedMessage =
            "다음 촬영을 위한 가이드가 생성되었어요."
        static let buttonTitle = "가이드로 촬영하기"
        static let buttonPlaceholder = " "
    }

    enum Layout {
        static let navBarTopPadding: CGFloat = 12
        static let spacerHeight: CGFloat = 1

        static let aspectRatioWidth: CGFloat = 329
        static let aspectRatioHeight: CGFloat = 585
        static let displayHorizontalPadding: CGFloat = 32
        static let displayTopPadding: CGFloat = 16
        static let displayBottomPadding: CGFloat = 20

        static let buttonHorizontalPadding: CGFloat = 24
        static let buttonBottomPadding: CGFloat = 43
    }
}
