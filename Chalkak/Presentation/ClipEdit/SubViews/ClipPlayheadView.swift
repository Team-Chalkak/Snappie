//
//  ClipPlayheadView.swift
//  Chalkak
//
//  Created by 배현진 on 1/15/26.
//

import SwiftUI

struct ClipPlayheadView: View {
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 30)
            .frame(maxHeight: .infinity)
            .overlay(
                Rectangle()
                    .fill(SnappieColor.matcha50)
                    .frame(width: 3)
            )
    }
}
