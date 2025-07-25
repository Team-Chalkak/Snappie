//
//  VideoPreviewWithOverlay.swift
//  Chalkak
//
//  Created by Youbin on 7/26/25.
//
import SwiftUI
import AVFoundation

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

    private enum Layout {
        static let horizontalSpacing: CGFloat = 50
        static let cornerRadius: CGFloat = 20
    }
}
