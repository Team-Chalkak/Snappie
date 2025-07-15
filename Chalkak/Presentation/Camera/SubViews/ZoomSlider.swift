//
//  ZoomSlider.swift
//  Chalkak
//
//  Created by 정종문 on 7/15/25.
//

import SwiftUI

/// 카메라 배율 조절 슬라이더
struct ZoomSlider: View {
    /// 현재 카메라의 줌 배율
    let zoomScale: CGFloat
    let minZoom: CGFloat
    let maxZoom: CGFloat
    let onValueChanged: (CGFloat) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.black.opacity(0.6))
                    .frame(height: 50)
                
                HStack {
                    ForEach(0 ..< 6, id: \.self) { index in
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 1, height: index == 0 || index == 5 ? 20 : 12)
                            .opacity(0.7)
                        
                        if index < 5 {
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 25)
                
                // 현재 줌 인디케이터
                Circle()
                    .fill(Color.white)
                    .frame(width: 30, height: 30)
                    .offset(x: calculateIndicatorOffset(geometry: geometry))
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        handleDrag(value: value, geometry: geometry)
                    }
            )
        }
        .frame(height: 50)
    }
    
    /// 드래그 제스처를 통해 줌 배율을 업데이트
    /// - Parameters:
    ///   - value: 드래그 제스처 값
    ///   - geometry: 슬라이더 지오메트리 정보
    private func handleDrag(value: DragGesture.Value, geometry: GeometryProxy) {
        guard geometry.size.width > 50,
              maxZoom > minZoom,
              maxZoom.isFinite,
              minZoom.isFinite
        else {
            return
        }
        
        let totalWidth = geometry.size.width - 50 // 양쪽 패딩
        let locationX = max(0, min(value.location.x - 25, totalWidth))
        let progress = totalWidth > 0 ? locationX / totalWidth : 0
        
        let newZoom = minZoom + (maxZoom - minZoom) * progress
        
        // 최종 안전 검사
        let safeZoom = max(minZoom, min(maxZoom, newZoom))
        if safeZoom.isFinite, !safeZoom.isNaN {
            onValueChanged(safeZoom)
        }
    }
    
    /// 현재 줌 배율에 따른 인디케이터 오프셋 계산
    /// - Parameter geometry: 슬라이더 뷰의 지오메트리 정보입니다.
    /// - Returns: 계산된 인디케이터의 x축 오프셋 값
    private func calculateIndicatorOffset(geometry: GeometryProxy) -> CGFloat {
        guard geometry.size.width > 50,
              maxZoom > minZoom,
              zoomScale.isFinite,
              !zoomScale.isNaN
        else {
            return 25
        }
        
        let totalWidth = geometry.size.width - 50
        let clampedZoom = max(minZoom, min(maxZoom, zoomScale))
        let progress = (maxZoom - minZoom) > 0 ? (clampedZoom - minZoom) / (maxZoom - minZoom) : 0
        let offset = 25 + (totalWidth * progress) - 15
        
        return max(10, min(geometry.size.width - 40, offset))
    }
}
