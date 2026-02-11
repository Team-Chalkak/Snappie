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
    let isSelected: Bool
    let isReordering: Bool
    let onDragStateChanged: (Bool) -> Void
    let onTap: () -> Void
    let isGuideClip: Bool
    
    @State private var showStroke: Bool = false

    private let clipWidth: CGFloat = 62
    private let clipHeight: CGFloat = 97
    private let clipRadius: CGFloat = 8

    var body: some View {
        Group {
            if let thumbnail = clip.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: clipWidth, height: clipHeight)
                    .overlay(alignment: .bottom) {
                        // clip duration
                        Text("\(String(format: "%.1f", clip.trimmedDuration))초")
                            .foregroundStyle(.matcha50)
                            .snappieStyle(.roundCaption1)
                            .shadow(color: .black.opacity(0.4), radius: 5)
                            .padding(.bottom, 8)
                    }
                    .overlay(alignment: .topLeading) {
                        if isGuideClip {
                            Image("silhouette")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                                .padding(2)
                                .background(
                                    Circle()
                                        .fill(SnappieColor.labelDarkNormal)
                                )
                                .padding(4)
                        }
                        
                    }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
        }
        .frame(width: clipWidth, height: clipHeight)
        .clipShape(RoundedRectangle(cornerRadius: clipRadius))
        .overlay {
            if showStroke {
                RoundedRectangle(cornerRadius: clipRadius)
                    .stroke(SnappieColor.primaryNormal, lineWidth: 2)
            }
        }
        .onTapGesture {
            onTap()
        }
        .onChange(of: isSelected && !isReordering) { oldValue, newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    showStroke = newValue
                }
            }

        }
    }
}
