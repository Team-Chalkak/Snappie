//
//  TiltFeedbackView.swift
//  Chalkak
//
//  Created by 석민솔 on 7/14/25.
//

import SwiftUI

/** 기울기 피드백을 원형 가이드에 맞춰서 보여주는 뷰

 이 뷰는 사용자의 offsetX, offsetY를 이용하여 기기 기울기를 시각적으로 표현하여 올바른 위치에 대한 피드백을 제공합니다.
 가이드 원과 피드백 원의 색상 변화를 통해 사용자가 적절한 위치에 있는지 알 수 있습니다.

 ## 사용 예제
 ```swift
 @StateObject private var tiltCollector: TiltDataCollector
 @StateObject private var tiltManager: TiltManager

 init(tiltCollector: TiltDataCollector = TiltDataCollector()) {
     self._tiltCollector = StateObject(wrappedValue: tiltCollector)
     self._tiltManager = StateObject(
        wrappedValue: TiltManager(
            properTilt: Tilt(degreeX: 0, degreeZ: -0.5),
            dataCollector: tiltCollector
        )
    )
 }
 
 var body: some View {
    TiltFeedbackView(
        offsetX: tiltManager.offsetX,
        offsetY: tiltManager.offsetZ
    )
 }
 ```

*/
struct TiltFeedbackView: View {
    // MARK: - Properties
    /// X축 기울기 오프셋 값: 기기의 좌우 기울기
    var offsetX: CGFloat
    
    /// Y축 기울기 오프셋 값: 기기의 앞뒤 기울기
    var offsetY: CGFloat
    
    /// 현재 위치가 적절한 범위 내에 있는지 확인하는 계산 프로퍼티
    var isProperPosition: Bool {
        if abs(offsetX) < 3 && abs(offsetY) < 3 {
            return true
        } else {
            return false
        }
    }
    
    // MARK: - init
    init(offsetX: Float, offsetY: Float) {
        self.offsetX = CGFloat(offsetX)
        self.offsetY = CGFloat(offsetY)
    }
    
    // MARK: - View
    var body: some View {
        // 가이드 동그라미
        Circle()
            .stroke(lineWidth: 1)
            .frame(width: 10, height: 10)
            .foregroundStyle(isProperPosition ? Color.blue : Color.white)
            .overlay(
                // 피드백 동그라미
                Circle()
                    .frame(width: 6, height: 6)
                    .offset(x: offsetX, y: offsetY)
                    .foregroundStyle(isProperPosition ? Color.blue : Color.white)
            )
    }
}

#Preview {
    TiltFeedbackView(offsetX: 0, offsetY: 0)
}
