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
        overlayViewModel.isOverlayReady ? "가이드로 촬영하기" : " "
    }
    
    // 3. init
    init(clip: Clip) {
        self.clip = clip
        self._overlayViewModel = StateObject(wrappedValue: OverlayViewModel(clip: clip))
    }
    
    var body: some View {
        ZStack {
            SnappieColor.darkHeavy.edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .center) {
                SnappieNavigationBar(
                    leftButtonType: .backward {
                        dismiss()
                    },
                    rightButtonType: .none
                )
                .padding(.top, 12)
                
                if overlayViewModel.isOverlayReady {
                    Spacer().frame(height: 1)
                    
                    Text("다음 촬영을 위한 가이드가 생성되었어요.")
                        .snappieStyle(.proBody1)
                        .foregroundStyle(SnappieColor.labelPrimaryNormal)
                    
                    OverlayDisplayView(overlayViewModel: overlayViewModel)
                        .aspectRatio(329 / 585, contentMode: .fill)
                        .padding(.horizontal, 32)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                    
                    Spacer()
                    
                } else {
                    // 대신 스켈레톤 뷰
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .foregroundStyle(.white)
                        .tint(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                }
                
                Button(action: {
                    if let newGuide = overlayViewModel.makeGuide(clipID: clip.id) {
                        guide = newGuide
                        coordinator.push(.boundingBox(guide: newGuide))
                    }
                }) {
                    Text(usingGuideText)
                        .snappieStyle(.proLabel1)
                        .padding(.horizontal, 24)
                }
                .buttonStyle(SnappieButtonStyle(styler: SolidPrimaryStyler(size: .large)))
                .padding(.bottom, 43)
            }
        }
        .onDisappear {
            overlayViewModel.dismissOverlay()
        }
    }
}

private extension OverlayView {
    enum Context {
        
    }

    enum Layout {
        
    }
}

struct OverlayView_Previews: PreviewProvider {
    static var previews: some View {
        let mockClip = Clip(
            id: UUID().uuidString,
            videoURL: URL(fileURLWithPath: "https://github.com/user-attachments/assets/d644553d-7709-4ecb-a7d8-6097c31e52ab"),
            originalDuration: 21.0,
            endPoint: 21.0,
            createdAt: Date()
        )

        NavigationStack {
            OverlayView(clip: mockClip)
                .environmentObject(MockCoordinator())
        }
    }
}

// MARK: - Mock Coordinator
class MockCoordinator: Coordinator {
    override func push(_ destination: Path) {
        print("Mock push to destination: \(destination)")
    }
}
