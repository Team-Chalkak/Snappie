//
//  PlayheadView.swift
//  Chalkak
//
//  Created by 석민솔 on 12/22/25.
//

import SwiftUI

/// 프로젝트 편집에 사용될 재생 막대 UI 서브뷰
struct PlayheadView: View {
    var body: some View {
        VStack(spacing: 2) {
            InvertedTriangle()
                .fill(Color.matcha400)
                .frame(width: 11, height: 13)
            
            RoundedRectangle(cornerRadius: 2)
                .fill(.matcha50)
                .frame(width: 1.7, height: 115)
                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 4)
        }
    }
}

/// 역삼각형 모양
struct InvertedTriangle: Shape {
    let cornerRadius: CGFloat = 1
    
    func path(in rect: CGRect) -> SwiftUI.Path {
        var path = SwiftUI.Path()
        
        let topLeft = CGPoint(x: rect.minX, y: rect.minY)
        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottom = CGPoint(x: rect.midX, y: rect.maxY)
        
        // 각 모서리에서 radius만큼 안쪽에서 시작
        path.move(to: topLeft)
        
        // 상단 선 → 오른쪽 모서리
        path.addArc(tangent1End: topRight,
                    tangent2End: bottom,
                    radius: cornerRadius)
        
        // 오른쪽 아래 선 → 아래 모서리
        path.addArc(tangent1End: bottom,
                    tangent2End: topLeft,
                    radius: cornerRadius)
        
        // 왼쪽 선 → 왼쪽 위 모서리
        path.addArc(tangent1End: topLeft,
                    tangent2End: topRight,
                    radius: cornerRadius)
        
        return path
    }
}
