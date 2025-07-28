//
//  ZoomSlider.swift
//  Chalkak
//
//  Created by 정종문 on 7/15/25.
//

import SwiftUI

/// 카메라 배율 조절 슬라이더
struct ZoomSlider: View {
    let zoomScale: CGFloat
    let minZoom: CGFloat
    let maxZoom: CGFloat
    let onValueChanged: (CGFloat) -> Void
    
    private let centerZoom: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Capsule()
                    .fill(SnappieColor.containerFillNormal)
                    .frame(height: 50)
                
                ZoomSliderLines(geometry: geometry)
                
                // 1.0x 중앙 기준점
                Rectangle()
                    .fill(SnappieColor.labelDarkInactive)
                    .frame(width: 1, height: 8)
                    .position(x: geometry.size.width / 2, y: 25)
                
                // 줌인디케이터 (줌 조절 커서역할)
                RoundedRectangle(cornerRadius: 8)
                    .fill(SnappieColor.labelPrimaryNormal)
                    .frame(width: 5, height: 38)
                    .position(x: calculateIndicatorPosition(geometry: geometry), y: 25)
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
    
    /// 1.0x 중심 기준 드래그 제스처
    private func handleDrag(value: DragGesture.Value, geometry: GeometryProxy) {
        let margin: CGFloat = 25 // 양쪽 여백
        let availableWidth = geometry.size.width - (margin * 2)
        let centerX = geometry.size.width / 2
        let halfWidth = availableWidth / 2
        let dragX = max(margin, min(geometry.size.width - margin, value.location.x)) // 드래그 범위 제한
        
        let newZoom: CGFloat
        
        if dragX < centerX {
            // 0.5 ~ 1.0
            let progress = (dragX - margin) / halfWidth
            newZoom = minZoom + (centerZoom - minZoom) * progress
        } else {
            // 1.0 ~ 끝까지
            let progress = (dragX - centerX) / halfWidth
            newZoom = centerZoom + (maxZoom - centerZoom) * progress
        }
        
        let safeZoom = max(minZoom, min(maxZoom, newZoom))
        if safeZoom.isFinite, !safeZoom.isNaN {
            onValueChanged(safeZoom)
        }
    }
    
    /// 1.0x 중심 기준 인디케이터 위치 계산
    private func calculateIndicatorPosition(geometry: GeometryProxy) -> CGFloat {
        let margin: CGFloat = 25 // 슬라이더 눈금으로인한 양쪽 여백
        let availableWidth = geometry.size.width - (margin * 2)
        let centerX = geometry.size.width / 2
        let halfWidth = availableWidth / 2
        
        if zoomScale < centerZoom {
            // 0.5 ~ 1.0
            let progress = (zoomScale - minZoom) / (centerZoom - minZoom)
            return margin + (progress * halfWidth)
        } else {
            // 1.0 ~ 끝까지
            let progress = (zoomScale - centerZoom) / (maxZoom - centerZoom)
            return centerX + (progress * halfWidth)
        }
    }
}

struct ZoomSliderLines: View {
    let geometry: GeometryProxy
    
    // 상수들
    private let totalLinesPerSide = 8
    private let margin: CGFloat = 25
    private let lineWidth: CGFloat = 2
    private let yPosition: CGFloat = 25
    
    var body: some View {
        ZStack {
            let centerX = geometry.size.width / 2
            let availableWidth = geometry.size.width - (margin * 2)
            let lineSpacing = availableWidth / CGFloat(totalLinesPerSide * 2)
            
            // 왼쪽 및 오른쪽 눈금 생성
            ForEach([-1, 1], id: \.self) { side in
                ForEach(1 ... totalLinesPerSide, id: \.self) { index in
                    let xPosition = centerX + CGFloat(side * index) * lineSpacing
                    let isWithinBounds = (side == -1) ? xPosition >= margin : xPosition <= geometry.size.width - margin
                    
                    if isWithinBounds {
                        let normalizedDistance = CGFloat(index) / CGFloat(totalLinesPerSide)
                        
                        Capsule()
                            .fill(SnappieColor.labelDarkInactive)
                            .frame(width: lineWidth, height: getLineHeight(for: normalizedDistance))
                            .position(x: xPosition, y: yPosition)
                    }
                }
            }
        }
    }
    
    private func getLineHeight(for normalizedDistance: CGFloat) -> CGFloat {
        let minHeight: CGFloat = 8
        let maxHeight: CGFloat = 35
        
        // 중앙에서 멀어질수록 선이 길어짐
        return minHeight + (maxHeight - minHeight) * normalizedDistance
    }
}
