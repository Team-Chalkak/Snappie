//
//  PlayTimeView.swift
//  Chalkak
//
//  Created by 배현진 on 7/28/25.
//

import SwiftUI

struct PlayTimeView: View {
    /// 전체 프로젝트 재생 위치
    let currentTime: Double
    /// 전체 프로젝트 길이
    let totalDuration: Double
    /// 트리밍 중인 클립이 있으면 전달
    let trimmingClip: EditableClip?

    private var displayText: String {
        if let clip = trimmingClip {
            // 트리밍 모드: 소수점 두 자리, 앞자리 0 패딩 없이
            return String(format: "%.2f초", clip.trimmedDuration)
        } else {
            // 일반 모드: 소수점 두 자리, 정수부 2자리 0패딩
            return String(
               format: "%05.2f / %05.2f",
               currentTime,
               totalDuration
            )
        }
    }

    var body: some View {
        Text(displayText)
            .font(.caption)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
    }
}
