//
//  ClipToolbarView.swift
//  Chalkak
//
//  Created by 석민솔 on 12/29/25.
//

import SwiftUI

struct ClipToolbarView: View {
    private let buttonWidth: CGFloat = 52
    private let buttonHeight: CGFloat = 40
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // 내리기 버튼
            Button {
                
            } label: {
                IconView(iconType: .chevronDown, scale: .xlarge)
                    .foregroundStyle(SnappieColor.labelPrimaryNormal)
                    .frame(width: buttonWidth, height: buttonHeight)
                    .contentShape(Rectangle())
            }
            
            // 장면 다듬기 버튼
            ToolButtonView(buttonStyle: .editClip) {
                // TODO: 장면 다듬기 이동
            }
            
            // 가이드 수정 버튼
            ToolButtonView(buttonStyle: .editGuide) {
                // TODO: 가이드 수정으로 이동
            }
            
            // 장면 삭제 버튼
            ToolButtonView(buttonStyle: .deleteClip) {
                // TODO: 장면 삭제 액션 실행
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
    }
}

#Preview {
    ClipToolbarView()
}



