//
//  PlayButtonControlView.swift
//  Chalkak
//
//  Created by 배현진 on 7/24/25.
//

import SwiftUI

struct PlayButtonControlView: View {
    @Binding var isPlaying: Bool
    let onPlayPauseTapped: () -> Void

    var body: some View {
        HStack {
            Spacer()

            Button(action: {
                onPlayPauseTapped()
            }) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
                    .shadow(radius: 3)
            }

            Spacer()
        }
        .padding(.vertical, 12)
    }
}
