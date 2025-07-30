//
//  ProjectThumbnailsView.swift
//  Chalkak
//
//  Created by 배현진 on 7/28/25.
//

import SwiftUI

struct ProjectThumbnailsView: View {
    let clip: EditableClip
    let fullWidth: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            ForEach(clip.thumbnails.indices, id: \.self) { i in
                Image(uiImage: clip.thumbnails[i])
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(
                        width: fullWidth / CGFloat(clip.thumbnails.count),
                        height: 60
                    )
                    .clipped()
            }
        }
        .frame(width: fullWidth, height: 60)
        .contentShape(Rectangle())
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
