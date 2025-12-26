//
//  EmptyProjectView.swift
//  Chalkak
//
//  Created by Youbin on 7/29/25.
//

import SwiftUI

/// 프로젝트가 비어있을 때의 안내 뷰
struct EmptyProjectView: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("나의 프로젝트")
                .font(.system(size: 22, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 32)

            Spacer()

            Text("프로젝트가 비어 있어요.\n촬영을 시작하여 새 프로젝트를 만들어볼까요?")
                .multilineTextAlignment(.center)
                .font(SnappieFont.style(.proLabel1))
                .foregroundStyle(SnappieColor.labelPrimaryNormal)
                .lineSpacing(10)

            Spacer()
        }
    }
}
