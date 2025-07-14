//
//  HeightFeedbackView.swift
//  Chalkak
//
//  Created by 석민솔 on 7/14/25.
//

import SwiftUI

/**
 높이가 특정 지점과 얼마나 일치하는지 시각적으로 피드백을 제공하는 뷰

 이 뷰는 중앙의 목표 지점을 기준으로 사용자의 현재 높이(또는 다른 값)가 얼마나 차이 나는지를
 움직이는 원으로 표시하여 직관적인 피드백을 줍니다.

 ## 사용 예시
 ```
 @StateObject private var heightManager = HeightManager(idealHeight: 1.1)

 var body: some View {
     ZStack {
         // AR 카메라 뷰
         HeightMeasurementARView(measuredHeight: $heightManager.measuredHeight, isGroundFound: $heightManager.isGroundFound)
             .edgesIgnoringSafeArea(.all)

         // 원점이 설정된 후에만 높이를 표시
         if heightManager.isGroundFound {
            HeightFeedbackView(offsetY: CGFloat(heightManager.offsetY))
                 .frame(maxWidth: .infinity, alignment: .leading)
                 .padding(.leading, 20)
         }
    }
 }
 ```

 - Parameters:
   - offsetY: 피드백을 나타내는 원의 수직 오프셋(offset) 값입니다.
              `0`은 중앙 목표 지점과의 일치를 의미하며, 양수 값은 아래로, 음수 값은 위로 원을 이동시킵니다.
 */
struct HeightFeedbackView: View {
    var offsetY: CGFloat
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("H")
                .fontWeight(.medium)
                .padding(.bottom, 6)
            
            RoundedRectangle(cornerRadius: 10)
                .frame(width: 14, height: 2)
            
            Rectangle()
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                .frame(width: 1, height: 90)
            
            Circle()
                .stroke(lineWidth: 1)
                .frame(width: 8, height: 8)
                .overlay(
                    // 피드백 동그라미
                    Circle()
                        .foregroundStyle(Color(red: 0, green: 0.57, blue: 1))
                        .frame(width:8, height: 8)
                        .offset(x: 0, y: offsetY)
                )
                .animation(.easeOut(duration: 0.1), value: offsetY)
            
            Rectangle()
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                .frame(width: 1, height: 90)
                .zIndex(-10) // 피드백 동그라미보다 밑으로 보내기
            
            RoundedRectangle(cornerRadius: 10)
                .frame(width: 14, height: 2)
            
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 8)
        .padding(.top, 11)
        .padding(.bottom, 20)
        .background(
            RoundedRectangle(cornerRadius: 40)
                .frame(width: 30)
                .foregroundStyle(Color.black.opacity(0.6))
        )
    }
}

#Preview {
    HeightFeedbackView(offsetY: 0.0)
}
