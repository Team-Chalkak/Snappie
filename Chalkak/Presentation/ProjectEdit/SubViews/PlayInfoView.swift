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
    let onPlayPauseTapped: () -> Void
    
    /// 전체 프로젝트 재생 위치
    let currentTime: Double
    /// 전체 프로젝트 길이
    let totalDuration: Double
    /// 트리밍 중인 클립이 있으면 전달
    let trimmingClip: EditableClip?
    /// 가이드 오버레이 버튼 활성화 여부
    let showOverlayToggle: Bool
    
    // for play button
    @Binding var isPlaying: Bool
    @Binding var isOverlayVisible: Bool
    
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
            .padding(.leading, 16)
            
            // 시간표시
            PlayTimeView(
                currentTime: currentTime,
                totalDuration: totalDuration,
                trimmingClip: trimmingClip
            )
            
            SnappieButton(
                .iconBackground(
                    icon: .silhouette,
                    size: .medium,
                    isActive: showOverlayToggle ? isOverlayVisible : false
                )
            ) {
                isOverlayVisible.toggle()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 16)
        }
    }
}
