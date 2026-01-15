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
            .fill(SnappieColor.matcha50)
            .frame(width: 3)
            .frame(maxHeight: .infinity)
    }
}
