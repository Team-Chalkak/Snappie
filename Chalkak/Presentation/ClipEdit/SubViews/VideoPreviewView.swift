//
//  VideoPreview.swift
//  Chalkak
//
//  Created by Youbin on 7/15/25.
//

import AVKit
import SwiftUI


/**
 VideoPreviewView: 영상 미리보기 뷰

 트리밍 중인 영상의 현재 상태를 보여주는 프리뷰 뷰.
 드래그 중일 때는 정적인 프리뷰 이미지, 그렇지 않으면 AVPlayer를 통한 영상 재생 화면

 ## 호출 위치
 - ClipEditView 내부에서 현재 영상 구간 시각화 용도로 사용됨
 - 호출 예시: `VideoPreviewView(previewImage: ..., player: ..., isDragging: ...)`
 */
struct VideoPreviewView: View {
    let previewImage: UIImage?
    let player: AVPlayer?
    let isDragging: Bool

    var body: some View {
        Group {
            if isDragging, let previewImage = previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .aspectRatio(9.0 / 16.0, contentMode: .fit)
            } else if let player = player {
                VideoPlayer(player: player)
                    .disabled(true)
                    .aspectRatio(9.0 / 16.0, contentMode: .fit)
                    .clipped()
            } else {
                //TODO: hifi 나오면 다시 한번 확인
                // 로딩 중일 때도 동일한 aspectRatio 공간 확보 임시 뷰
                ZStack {
                    Rectangle()
                        .fill(SnappieColor.darkStrong)
                    
                    ProgressView()
                        .foregroundColor(SnappieColor.primaryLight)
                        .font(SnappieFont.style(.kronaLabel1))
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(2.0)
                        .tint(SnappieColor.primaryLight)
                }
                .aspectRatio(9.0 / 16.0, contentMode: .fit)
            }
        }
    }
}
