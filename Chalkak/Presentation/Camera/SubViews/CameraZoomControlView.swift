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
    @State private var longPressStarted = false

    // 줌 활성범위
    private let zoomRanges = [
        ZoomRange(label: ".5", min: 0.0, max: 0.95, activeWidth: 50),
        ZoomRange(label: "1", min: 0.95, max: 1.9, activeWidth: 60),
        ZoomRange(label: "2", min: 2.0, max: .infinity, activeWidth: 60)
    ]

    // 줌 버튼 기본 설정값
    private let zoomPresets: [CGFloat] = [0.5, 1.0, 2.0]

    var body: some View {
        VStack(spacing: 8) {
            // 줌 인디케이터
            HStack(spacing: 8) {
                ForEach(Array(zoomRanges.enumerated()), id: \.element.label) { index, range in
                    createZoomButton(for: range, at: index)
                }
            }
            .padding(.all, 8)
            .background(SnappieColor.darkHeavy.opacity(0.3))
            .clipShape(Capsule())
            .offset(y: viewModel.showingZoomControl ? -10 : 0) // 인디케이터 상승 인터렉션

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
    
    // 복잡한 제스처 로직을 별도 함수로 분리
    @ViewBuilder
    private func createZoomButton(for range: ZoomRange, at index: Int) -> some View {
        let isActive = range.isActive(viewModel.zoomScale)
        let buttonText = isActive ? String(format: "%.1fx", viewModel.zoomScale) : range.label
        let buttonWidth: CGFloat = isActive ? range.activeWidth : 32
        
        ZoomButton(
            text: buttonText,
            isActive: isActive,
            width: buttonWidth
        )
        .onTapGesture {
            handleTapGesture(for: range, at: index)
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            handleLongPressGesture()
        }
    }
    
    // 탭 제스처 처리
    private func handleTapGesture(for range: ZoomRange, at index: Int) {
        let isButtonActive = range.isActive(viewModel.zoomScale)
        // 슬라이더가 열려있어도 버튼을 탭할 수 있도록 수정
        // 타이머가 실행 중이 아니고, 현재 활성화된 버튼이 아닌 경우에만 탭 가능
        let canTap = !isButtonActive && !viewModel.isTimerRunning
        
        if canTap {
            let targetZoom = zoomPresets[index]
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.selectZoomScale(targetZoom)
            }
        }
    }
    
    // 롱프레스 제스처 처리
    private func handleLongPressGesture() {
        if !viewModel.isTimerRunning {
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.toggleZoomControl()
            }
        }
    }
}
