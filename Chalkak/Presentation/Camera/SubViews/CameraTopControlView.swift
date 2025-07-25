//
//  CameraTopControlView.swift
//  Chalkak
//
//  Created by 정종문 on 7/15/25.
//

import SwiftUI

struct CameraTopControlView: View {
    @ObservedObject var viewModel: CameraViewModel

    var body: some View {
        HStack {
            if viewModel.isRecording {
                HStack(spacing: 3) {
                    Circle()
                        .fill(SnappieColor.redRecording)
                        .frame(width: 8, height: 8)
                    Text(viewModel.formattedTime)
                        .font(SnappieFont.style(.kronaLabel1))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(SnappieColor.gradientFillNormal)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                CameraDefaultTopControlView(viewModel: viewModel)
            }
        }.padding(.top, 50)
    }
}
