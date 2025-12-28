//
//  ClipToolbarView.swift
//  Chalkak
//
//  Created by 석민솔 on 12/29/25.
//

import SwiftUI

struct ClipToolbarView: View {
    let hideToolbar: () -> Void
    let onTapEditClip: () -> Void
    let onTapEditGuide: () -> Void
    let onTapDeleteClip: () -> Void

    private let buttonWidth: CGFloat = 52
    private let buttonHeight: CGFloat = 40

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // 내리기 버튼
            Button {
                hideToolbar()
            } label: {
                IconView(iconType: .chevronDown, scale: .xlarge)
                    .foregroundStyle(SnappieColor.labelPrimaryNormal)
                    .frame(width: buttonWidth, height: buttonHeight)
                    .contentShape(Rectangle())
            }
            
            // 장면 다듬기 버튼
            ToolButtonView(buttonStyle: .editClip) {
                onTapEditClip()
            }
            
            // 가이드 수정 버튼
            ToolButtonView(buttonStyle: .editGuide) {
                onTapEditGuide()
            }
            
            // 장면 삭제 버튼
            ToolButtonView(buttonStyle: .deleteClip) {
                onTapDeleteClip()
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
    }
}


