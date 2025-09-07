//
//  HorizontalLevelIndicator.swift
//  Chalkak
//
//  Created by 정종문 on 7/24/25.
//

import SwiftUI

struct HorizontalLevelIndicatorView: View {
    let gravityX: Double
    @State private var opacity: Double = 1.0
    @State private var horizontalTimer: Timer?
    @State private var hiddenByHorizontal: Bool = false // 수평이라서 사라졌을때

    // 수평 여부 판정(-0.05~0.05사이면 수평)
    private var isHorizontal: Bool {
        abs(gravityX) < 0.05
    }

    // 기울기 각도(수평 보정 tilt 보정값과 동일하게 0.05이하일때 스냅 붙음)
    private var tiltAngle: Double {
        // 수평 상태일 때는 색상변화만 주지않고, 각도 역시 0.0으로 수평값으로 보정값이 적용
        if isHorizontal {
            return 0.0
        }

        let maxAngle = 30.0 // 최대 표시 각도 (15도까지 보여주지만 maxAngle값을 높게잡아야 기울기가 올라감)
        let clampedGravity = max(-0.5, min(0.5, gravityX))
        return clampedGravity * maxAngle * 2
    }

    /// 실제 기울기 각도 (수평 기준에서 기기가 얼마나 기울어졌는지를 도(degree) 단위로 계산)
    private var actualTiltDegrees: Double {
        // gravityX는 -1(왼쪽으로 완전히 기울어짐) ~ 1(오른쪽으로 완전히 기울어짐) 사이의 값
        // 이 값은 사인값이므로 arcsin(역사인)을 통해 각도(라디안)를 구한 뒤, 도 단위로 변환
        let clampedGravity = max(-1.0, min(1.0, gravityX))
        return asin(clampedGravity) * 180.0 / .pi
    }

    // 선 색상
    private var lineColor: Color {
        isHorizontal ? SnappieColor.labelPrimaryActive : SnappieColor.labelPrimaryNormal
    }

    var body: some View {
        ZStack {
            /// 양옆 고정 기준선들 (회전하지 않음)
            ///  양옆 고정 20px + 중앙 공백 121
            HStack(spacing: 0) {
                levelLine(width: 20) // 왼쪽 고정선
                spacer(width: 121) // 일직선 시소 영역(공백)
                levelLine(width: 20) // 오른쪽 고정선
            }
            /// 회전하는 시소 부분
            /// 양옆 공백 20 px + 중앙 일직선 121
            HStack(spacing: 0) {
                spacer(width: 20)
                HStack(spacing: 0) {
                    levelLine(width: 48)
                    spacer(width: 25) // 중앙 선 사이 공백
                    levelLine(width: 48)
                }
                .rotationEffect(.degrees(tiltAngle), anchor: .center)
                spacer(width: 20)
            }
        }
        .frame(height: 50)
        .opacity(opacity)
        .animation(.easeInOut(duration: 0.1), value: tiltAngle)
        .animation(.easeInOut(duration: 0.2), value: lineColor)
        .animation(.easeInOut(duration: 0.3), value: opacity)
        .onChange(of: isHorizontal) { _, newisHorizontal in
            handleLevelChange(newisHorizontal)
        }
        .onChange(of: actualTiltDegrees) { _, _ in
            checkAngleLimit()
        }
        .onAppear {
            checkAngleLimit()
            if isHorizontal {
                handleLevelChange(true)
            }
        }
        .onDisappear {
            horizontalTimer?.invalidate()
            horizontalTimer = nil
        }
    }

    /// 수평선
    private func levelLine(width: CGFloat) -> some View {
        Rectangle()
            .frame(width: width, height: 1)
            .foregroundColor(lineColor)
    }

    /// 투명 여백
    private func spacer(width: CGFloat) -> some View {
        Color.clear.frame(width: width, height: 1)
    }

    /// 수평일때 or 각도가15도이상 벗어났을때  dissove처리를 위한 메소드
    private func handleLevelChange(_ isNowHorizontal: Bool) {
        if isNowHorizontal {
            // 수평이되면 타이머 시작 (1초후 디졸브처리위함)
            horizontalTimer?.invalidate()
            horizontalTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.opacity = 0
                    self.hiddenByHorizontal = true // 수평시 숨겨짐 상태
                }
            }
        } else {
            // 수평이 아니면 타이머 취소하고 표시
            horizontalTimer?.invalidate()
            horizontalTimer = nil

            // 수평 상태로 숨겨진 상태였다면 각도가 어긋났으니 다시 등장
            if hiddenByHorizontal {
                hiddenByHorizontal = false
                withAnimation(.easeInOut(duration: 0.3)) {
                    opacity = 1
                }
            }
        }
    }

    private func checkAngleLimit() {
        let currentAngle = abs(actualTiltDegrees)

        if currentAngle > 15 {
            // 15도 초과시에는 수평계 표시안함
            horizontalTimer?.invalidate()
            horizontalTimer = nil
            hiddenByHorizontal = false // 각도 제한초과시 사라짐
            withAnimation(.easeInOut(duration: 0.3)) {
                opacity = 0
            }
        } else if opacity == 0, !hiddenByHorizontal, !isHorizontal {
            // 15도보다 적으면서,수평아닐때
            withAnimation(.easeInOut(duration: 0.3)) {
                opacity = 1
            }
        }
    }
}
