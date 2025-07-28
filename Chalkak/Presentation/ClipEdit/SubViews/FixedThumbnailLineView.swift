//
//  FixedThumbnailLineView.swift
//  Chalkak
//
//  Created by Youbin on 7/27/25.
//

import SwiftUI

struct FixedThumbnailLineView: View {
    let editViewModel: ClipEditViewModel

    var body: some View {
        let thumbnailWidth = editViewModel.thumbnailWidth(for: Layout.lineWidth)

        HStack(spacing: 0) {
            TrimmingHandleView(isStart: true, isDimmed: true)

            ForEach(editViewModel.thumbnails, id: \.self) { image in
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: thumbnailWidth, height: Layout.thumbnailHeight)
                    .clipped()
            }

            TrimmingHandleView(isStart: false, isDimmed: true)
        }
        .frame(width: Layout.lineWidth, height: Layout.thumbnailHeight)
    }
}


// MARK: - Layout Constants
private extension FixedThumbnailLineView {
    enum Layout {
        static let lineWidth: CGFloat = 305
        static let handleWidth: CGFloat = 20
        static let thumbnailHeight: CGFloat = 60
    }
}
