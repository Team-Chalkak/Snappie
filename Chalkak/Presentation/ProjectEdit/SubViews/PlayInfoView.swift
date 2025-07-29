//
//  PlayInfoView.swift
//  Chalkak
//
//  Created by 석민솔 on 7/29/25.
//

import SwiftUI

/// 재생,일시정지 버튼 & 시간표시하는 서브뷰
struct PlayInfoView: View {
    // MARK: input properties
    // for play button
    @Binding var isPlaying: Bool
    let onPlayPauseTapped: () -> Void
    
    // for playtimeView
    /// 전체 프로젝트 재생 위치
    let currentTime: Double
    /// 전체 프로젝트 길이
    let totalDuration: Double
    /// 트리밍 중인 클립이 있으면 전달
    let trimmingClip: EditableClip?
    
    
    // MARK: body
    var body: some View {
        ZStack(alignment: .center) {
            // 재생 일시정지 버튼
            SnappieButton(
                .iconBackground(
                    icon: isPlaying ? .pauseFill : .playFill,
                    size: .medium,
                    isActive: true
                ),
                action: onPlayPauseTapped
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 24)
            
            // 시간표시
            PlayTimeView(
                currentTime: currentTime,
                totalDuration: totalDuration,
                trimmingClip: trimmingClip
            )
        }
    }
}
