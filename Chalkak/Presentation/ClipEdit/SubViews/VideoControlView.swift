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
            
            VideoPreviewWithOverlay(
                previewImage: editViewModel.previewImage,
                player: editViewModel.player,
                isDragging: isDragging,
                overlayImage: overlayImage,
                isOverlayVisible: isOverlayVisible
            )
            
            VideoControlSession(
                editViewModel: editViewModel,
                isOverlayVisible: $isOverlayVisible,
                overlayImage: overlayImage
            )
        })
    }
}
