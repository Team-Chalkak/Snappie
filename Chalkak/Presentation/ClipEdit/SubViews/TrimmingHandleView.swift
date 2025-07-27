//
//  TrimmingHandleView.swift
//  Chalkak
//
//  Created by Youbin on 7/27/25.
//

import SwiftUI

struct TrimmingHandleView: View {
    let isStart: Bool
    
    var body: some View {
        UnevenRoundedRectangle(
            cornerRadii: .init(
                topLeading: isStart ? 6 : 0,
                bottomLeading: isStart ? 6 : 0,
                bottomTrailing: isStart ? 0 : 6,
                topTrailing: isStart ? 0 : 6
            )
        )
        .fill(SnappieColor.primaryNormal)
        .frame(width: Layout.handleWidth, height: Layout.handleHeight)
        .overlay {
            Capsule()
                .fill(SnappieColor.darkStrong)
                .frame(width: 3, height: 29)
        }
    }
}

enum Layout {
    static let handleWidth: CGFloat = 20
    static let handleHeight: CGFloat = 60
}

#Preview {
    TrimmingHandleView(isStart: false)
}
