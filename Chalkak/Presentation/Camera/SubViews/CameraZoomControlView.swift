//
//  CameraZoomControlView.swift
//  Chalkak
//
//  Created by 정종문 on 7/25/25.
//

import SwiftUI

private struct ZoomRange {
    let label: String
    let min: CGFloat
    let max: CGFloat
    let activeWidth: CGFloat

    func isActive(_ currentZoom: CGFloat) -> Bool {
        return currentZoom >= min && currentZoom < max
    }
}

struct CameraZoomControlView: View {
    @ObservedObject var viewModel: CameraViewModel

    // 줌 활성범위
    private let zoomRanges = [
        ZoomRange(label: ".5", min: 0.0, max: 0.9, activeWidth: 50),
        ZoomRange(label: "1", min: 1.0, max: 1.9, activeWidth: 60),
        ZoomRange(label: "2", min: 2.0, max: .infinity, activeWidth: 60)
    ]

    var body: some View {
        VStack(spacing: 8) {
            // 줌 인디케이터
            HStack(spacing: 8) {
                ForEach(zoomRanges, id: \.label) { range in
                    ZoomButton(
                        text: range.isActive(viewModel.zoomScale) ?
                            String(format: "%.1fx", viewModel.zoomScale) : range.label,
                        isActive: range.isActive(viewModel.zoomScale),
                        width: range.isActive(viewModel.zoomScale) ? range.activeWidth : 32
                    )
                }
            }
            .padding(.all, 8)
            .background(SnappieColor.darkHeavy.opacity(0.3))
            .clipShape(Capsule())
            .offset(y: viewModel.showingZoomControl ? -10 : 0) // 인디케이터 상승 인터렉션
            // 롱프레스 줌 슬라이더 적용
            .onLongPressGesture(minimumDuration: 0.5) {
                if !viewModel.isTimerRunning {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.toggleZoomControl()
                    }
                }
            }

            // 인디케이터 하단 줌 슬라이더
            if viewModel.showingZoomControl && !viewModel.isTimerRunning {
                ZoomSlider(
                    zoomScale: viewModel.zoomScale,
                    minZoom: viewModel.minZoomScale,
                    maxZoom: viewModel.maxZoomScale,
                    onValueChanged: { newValue in
                        viewModel.selectZoomScale(newValue)
                    }
                )
                // TODO: width 고정값 수정
                .frame(width: 320, height: 40)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showingZoomControl)
    }
}
