//
//  VideoPreviewWithOverlay.swift
//  Chalkak
//
//  Created by Youbin on 7/26/25.
//
import SwiftUI
import AVFoundation

/**
 VideoPreviewWithOverlay: 영상과 윤곽선 오버레이를 함께 표시하는 프리뷰 컴포넌트

 사용자가 드래그 중인 경우 프리뷰 이미지를 표시하고,
 재생 중인 경우 AVPlayer를 통해 영상을 실시간 재생합니다.
 Vision 기반으로 추출한 윤곽선 오버레이 이미지가 있다면 함께 표시됩니다.

 ## 구성 요소
 - VideoPreviewView: 정지 이미지 또는 AVPlayer를 통한 영상 출력
 - Overlay Layer: silhouette 이미지 표시 (`isOverlayVisible`이 true일 경우만)

 ## 호출 위치
 - VideoControlView 내부에서 영상 미리보기 파트로 사용됨\
 - 호출 예시
    VideoPreviewWithOverlay(
        previewImage: editViewModel.previewImage,
        player: editViewModel.player,
        isDragging: isDragging,
        overlayImage: overlayImage,
        isOverlayVisible: isOverlayVisible
    )
 */
struct VideoPreviewWithOverlay: View {
    let previewImage: UIImage?
    let player: AVPlayer?
    let isDragging: Bool
    let overlayImage: UIImage?
    let isOverlayVisible: Bool

    var body: some View {
        ZStack {
            VideoPreviewView(
                previewImage: previewImage,
                player: player,
                isDragging: isDragging
            )

            if isOverlayVisible, let overlayImage {
                Image(uiImage: overlayImage)
                    .resizable()
                    .scaledToFit()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .padding(.horizontal, Layout.horizontalSpacing)
    }
}

// MARK: - Layout Constants
private extension VideoPreviewWithOverlay {
    enum Layout {
        static let horizontalSpacing: CGFloat = 50
        static let cornerRadius: CGFloat = 20
    }
}

