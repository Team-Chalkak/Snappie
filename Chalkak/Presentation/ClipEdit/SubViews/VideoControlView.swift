//
//  VideoControlView.swift
//  Chalkak
//
//  Created by Youbin on 7/24/25.
//

import SwiftUI
import AVFoundation

struct VideoControlView: View {
    let isDragging: Bool
    let overlayImage: UIImage?
    
    @ObservedObject var editViewModel: ClipEditViewModel
    @State private var isOverlayVisible: Bool = true
    
    var body: some View {
        VStack(alignment: .center, spacing: 16 ,content: {
            
            videoPreview
            
            controlSession
            
        })
    }
    
    //MARK: - 비디오프리뷰 + 오버레이
    private var videoPreview: some View {
        ZStack {
            // 영상
            VideoPreviewView(
                previewImage: editViewModel.previewImage,
                player: editViewModel.player,
                isDragging: isDragging
            )

            // 오버레이
            if isOverlayVisible, let overlayImage = overlayImage {
                Image(uiImage: overlayImage)
                    .resizable()
                    .scaledToFit()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .padding(.horizontal, Layout.horizontalSpacing)
    }
    
    //MARK: - 컨트롤 세션(재생 버튼, 영상 길이, 가이드 on/off)
    private var controlSession: some View {
        HStack(alignment: .center, spacing: 108, content: {
            
            SnappieButton(
                .iconBackground(
                    icon: editViewModel.isPlaying ? .pauseFill : .playFill,
                    size: .medium
                )
            ) {
                editViewModel.togglePlayback()
            }
            
            //TODO: - duration 적용되면 여기 사용!
            Text(String(format: "%.2f초", editViewModel.currentTrimmedDuration))
                .font(SnappieFont.style(.proLabel3))
                .padding(.horizontal, 9.5)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(SnappieColor.primaryStrong)
                )
            
            if overlayImage != nil {
                SnappieButton(
                    .iconBackground(
                        //TODO: - 아이콘 on/off시 버튼 ui 변경
                        icon: isOverlayVisible ? .silhouette : .silhouette,
                        size: .medium)
                ) {
                    isOverlayVisible.toggle()
                }
            } else {
                Spacer()
            }
        })
        .padding(.horizontal, 23)
    }
}

private extension VideoControlView {
    enum Layout {
        static let horizontalSpacing: CGFloat = 50
        static let cornerRadius: CGFloat = 20
    }
}

