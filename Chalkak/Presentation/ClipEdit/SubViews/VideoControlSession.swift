//
//  VideoControlSession.swift
//  Chalkak
//
//  Created by Youbin on 7/26/25.
//

//  ControlSession.swift

import SwiftUI

struct VideoControlSession: View {
    @ObservedObject var editViewModel: ClipEditViewModel
    @Binding var isOverlayVisible: Bool
    let overlayImage: UIImage?

    var body: some View {
        HStack(alignment: .center, spacing: 108) {
            SnappieButton(
                .iconBackground(
                    icon: editViewModel.isPlaying ? .pauseFill : .playFill,
                    size: .medium
                )
            ) {
                editViewModel.togglePlayback()
            }

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
                        icon: isOverlayVisible ? .silhouette : .silhouette,
                        size: .medium
                    )
                ) {
                    isOverlayVisible.toggle()
                }
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 23)
    }
}
