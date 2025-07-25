//
//  VideoControlView.swift
//  Chalkak
//
//  Created by Youbin on 7/24/25.
//

import SwiftUI
import AVFoundation

/**
 VideoControlView: 영상 미리보기 및 조작 인터페이스

 사용자가 트리밍 중인 영상의 현재 상태를 확인하고, 영상 재생/일시정지, 오버레이 토글 등 다양한 조작을 수행할 수 있도록 도와주는 프리뷰 영상을 컨트롤하는 메인 뷰입니다.

 ## 구성 요소(서브뷰)
 - VideoPreviewWithOverlay: 정지 이미지 또는 AVPlayer 기반 영상과 오버레이를 함께 표시
 - VideoControlPanelView: 재생/일시정지 버튼, 트리밍된 길이 표시, 오버레이 on/off 버튼 포함

 ## 호출 위치
 - `ClipEditView` 내부에서 영상 조작 뷰로 사용됨
 - 호출 예시
    VideoControlView(
        isDragging: isDragging,
        overlayImage: guide?.outlineImage,
        editViewModel: editViewModel
    )
 */
struct VideoControlView: View {
    let isDragging: Bool
    let overlayImage: UIImage?
    
    @ObservedObject var editViewModel: ClipEditViewModel
    @State private var isOverlayVisible: Bool = true
    
    var body: some View {
        VStack(alignment: .center, spacing: 16 ,content: {
            
            VideoPreviewWithOverlay(
                previewImage: editViewModel.previewImage,
                player: editViewModel.player,
                isDragging: isDragging,
                overlayImage: overlayImage,
                isOverlayVisible: isOverlayVisible
            )
            
            VideoControlPanelView(
                editViewModel: editViewModel,
                isOverlayVisible: $isOverlayVisible,
                overlayImage: overlayImage
            )
        })
    }
}
