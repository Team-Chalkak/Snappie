//
//  TrimmingTimeDisplayView.swift
//  Chalkak
//
//  Created by Youbin on 7/26/25.
//

import SwiftUI

struct TrimmingTimeDisplayView: View {
    @ObservedObject var editViewModel: ClipEditViewModel
    
    var body: some View {
        HStack(content: {
            //TODO: 현재 영상 시간
            Text("00:00")
                .font(SnappieFont.style(.roundCaption1))
                .foregroundStyle(SnappieColor.primaryHeavy)
            
            Spacer()
            
            //TODO: 원본 영상 길이
            Text("00.15")
                .font(SnappieFont.style(.roundCaption1))
                .foregroundStyle(SnappieColor.primaryHeavy)
        })
        .padding(.horizontal, 24)
    }
}
