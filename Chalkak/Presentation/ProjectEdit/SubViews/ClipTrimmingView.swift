//
//  ClipTrimmingView.swift
//  Chalkak
//
//  Created by 배현진 on 7/24/25.
//

import SwiftUI

struct ClipTrimmingView: View {
    let clip: EditableClip
    @Binding var isDragging: Bool
    let onDragStateChanged: (Bool) -> Void

    private let clipWidth: CGFloat = 62
    private let clipHeight: CGFloat = 97
    private let clipRadius: CGFloat = 8

    var body: some View {
        Group {
            if let thumbnail = clip.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
        }
        .frame(width: clipWidth, height: clipHeight)
        .clipShape(RoundedRectangle(cornerRadius: clipRadius))
    }
}
