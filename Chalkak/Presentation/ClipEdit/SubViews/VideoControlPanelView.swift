//
//  VideoControlPanelView.swift
//  Chalkak
//
//  Created by Youbin on 7/26/25.
//

//  VideoControlPanelView.swift

import SwiftUI

/**
 VideoControlPanelView: 영상 재생 및 오버레이 조작 인터페이스

 트리밍 중인 영상에 대해 재생/일시정지, 트리밍된 구간 길이 확인, 윤곽선 오버레이 on/off 버튼 등의 기능을 제공합니다.

 ## 구성 요소
 - 재생/일시정지 버튼: AVPlayer 재생 상태를 토글
 - 트리밍 길이 표시: `startPoint` ~ `endPoint` 간 구간 길이를 실시간으로 표시
 - 오버레이 토글 버튼: 윤곽선 오버레이 가시성을 전환

 ## 호출 위치
 - `VideoControlView` 내부 하단의 영상 조작 영역으로 사용됨
 - 호출 예시
    VideoControlPanelView(
        editViewModel: editViewModel,
        isOverlayVisible: $isOverlayVisible,
        overlayImage: overlayImage
    )
 */
struct VideoControlPanelView: View {
    @ObservedObject var editViewModel: ClipEditViewModel
    @Binding var isOverlayVisible: Bool
    let overlayImage: UIImage?

    var body: some View {
        HStack(alignment: .center, spacing: 108) {
            SnappieButton(
                .iconBackground(
                    icon: editViewModel.isPlaying ? .pauseFill : .playFill,
                    size: .medium,
                    isActive: true
                )
            ) {
                editViewModel.togglePlayback()
            }

            Text(String(format: "%.2f초", editViewModel.currentTrimmedDuration))
                .font(SnappieFont.style(.proLabel3))
                .padding(.horizontal, 9.5)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(SnappieColor.primaryStrong)
                )

            if overlayImage != nil {
                SnappieButton(
                    .iconBackground(
                        icon: .silhouette,
                        size: .medium,
                        isActive: isOverlayVisible
                    )
                ) {
                    isOverlayVisible.toggle()
                }
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 23)
    }
}
