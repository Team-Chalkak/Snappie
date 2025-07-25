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
            VideoPreviewView(
                previewImage: editViewModel.previewImage,
                player: editViewModel.player,
                isDragging: isDragging
            )

            if isOverlayVisible, let overlayImage = overlayImage {
                Image(uiImage: overlayImage)
                    .resizable()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .padding(.horizontal, Layout.horizontalSpacing)
    }
    
    //MARK: - 컨트롤 세션(재생 버튼, 영상 길이, 가이드 on/off)
    private var controlSession: some View {
        HStack(alignment: .center, spacing: 109, content: {
            Button(action: {
                editViewModel.togglePlayback()
            }, label: {
                Image(editViewModel.isPlaying ? "pauseBtn" : "playBtn")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.white)
            })
            
            //TODO: - duration 적용되면 여기 사용!
            Text("0.00초")
                .foregroundColor(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.matcha600)
                )
            
            if overlayImage != nil {
                Button(action: {
                    isOverlayVisible.toggle()
                }, label: {
                    Image(systemName: isOverlayVisible ? "eye.fill" : "eye.slash.fill")
                        .resizable()
                        .frame(width: 28, height: 20)
                        .foregroundColor(.white)
                })
            } else {
                Spacer()
            }
        })
        .padding(.horizontal, 23)
    }
}

private extension VideoControlView {
    enum Layout {
        static let horizontalSpacing: CGFloat = 42
        static let cornerRadius: CGFloat = 20
    }
}

