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

    /// 원하는 썸네일 개수 (초당 3개)
    private var countWanted: Int {
        let duration = clip.isTrimming ? clip.originalDuration : clip.trimmedDuration
        let rate: Double = 3 // 초당 썸네일 개수
        return max(1, Int(floor(duration * rate)))
    }

    /// 실제 표시할 썸네일 배열
    private var thumbsToShow: [UIImage] {
        let available = clip.thumbnails.count
        let n = min(countWanted, available)
        guard available > n else { return clip.thumbnails }
        let step = Double(available - 1) / Double(n - 1)
        return (0..<n).map { idx in
            let i = Int(round(step * Double(idx)))
            return clip.thumbnails[i]
        }
    }

    /// 썸네일 하나당 너비
    private var thumbnailWidth: CGFloat {
        fullWidth / CGFloat(max(thumbsToShow.count, 1))
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(thumbsToShow.enumerated()), id: \.0) { _, img in
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: thumbnailWidth, height: 60)
                    .clipped()
            }
        }
        .frame(width: fullWidth, height: 60)
        .contentShape(Rectangle())
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
