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
    // MARK: input properties
    /// X축 기울기 오프셋 값: 기기의 좌우 기울기
    var offsetX: CGFloat
    
    /// Y축 기울기 오프셋 값: 기기의 앞뒤 기울기
    var offsetY: CGFloat
    
    // MARK: computed properties
    /// 자주 사용되는 offset 절대값
    var absOffsetX: CGFloat {
        abs(offsetX)
    }
    
    var absOffsetY: CGFloat {
        abs(offsetY)
    }
    
    /// 현재 위치가 적절한 범위 내에 있는지 확인하는 계산 프로퍼티
    var isProperPosition: Bool {
        if absOffsetX < 3 && absOffsetY < 3 {
            return true
        } else {
            return false
        }
    }
    
    /// 원의 투명도 결정하는 계산 프로퍼티
    var circleOpacity: Double {
        // 50 이상이면 안보이게
        if absOffsetX > 50 || absOffsetY > 50 {
            return 0
        }
        // 40부터 50까지 디졸브
        else if absOffsetX > 40 || absOffsetY > 40 {
            let offsetToCalc = max(absOffsetX, absOffsetY)
            return (50 - offsetToCalc) / 10
        }
        // 40 미만이면 100프로
        else {
            return 1
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
            .frame(width: 12, height: 12)
            .foregroundStyle(isProperPosition ? SnappieColor.primaryNormal : Color.matcha50)
            .overlay(
                // 피드백 동그라미
                Circle()
                    .frame(width: 8.5, height: 8.5)
                    .offset(
                        x: isProperPosition ? 0 : offsetX,
                        y: isProperPosition ? 0 : offsetY
                    )
                    .foregroundStyle(isProperPosition ? SnappieColor.primaryNormal : Color.matcha50)
                    .animation(.easeInOut(duration: 0.3), value: isProperPosition)
            )
            .opacity(circleOpacity)
            .animation(.smooth, value: circleOpacity)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.7)
            .ignoresSafeArea()
        
        TiltFeedbackView(offsetX: -40, offsetY: -45)
    }
}
