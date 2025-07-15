//
//  VideoPreview.swift
//  Chalkak
//
//  Created by Youbin on 7/15/25.
//

import SwiftUI
import AVKit

/// 비디오 프리뷰
struct VideoPreviewView: View {
    let previewImage: UIImage?
    let player: AVPlayer?
    let isDragging: Bool

    var body: some View {
        Group {
            if isDragging, let previewImage = previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 296, height: 526)
            } else if let player = player {
                VideoPlayer(player: player)
                    .frame(width: 296, height: 526)
            } else {
                Text("영상을 불러오는 중...")
            }
        }
    }
}
