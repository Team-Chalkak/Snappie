//
//  PlayTimeView.swift
//  Chalkak
//
//  Created by 배현진 on 7/28/25.
//

import SwiftUI

struct PlayTimeView: View {
    // MARK: input properties
    /// 전체 프로젝트 재생 위치
    let currentTime: Double
    /// 전체 프로젝트 길이
    let totalDuration: Double
    /// 트리밍 중인 클립이 있으면 전달
    let trimmingClip: EditableClip?

    // MARK: computed properties
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

    // MARK: body
    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            Spacer()
            
            if let clip = trimmingClip {
                // 트리밍 모드: 소수점 두 자리, 앞자리 0 패딩 없이
                Text(String(format: "%.2f초", clip.trimmedDuration))
                    .font(SnappieFont.style(.proLabel3))
                    .foregroundStyle(SnappieColor.labelDarkNormal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(SnappieColor.primaryStrong)
                    )
            }
            else {
                // 일반 모드: MM:SS
                Group {
                    Text(formattedTime(currentTime))
                        .foregroundStyle(Color.white)
                    
                    Text("/")
                        .foregroundStyle(SnappieColor.labelPrimaryDisable)
                    
                    Text(formattedTime(totalDuration))
                        .foregroundStyle(SnappieColor.labelPrimaryDisable)
                }
                .font(.system(
                    size: 14,
                    weight: .regular,
                    design: .rounded
                ))
            }
            
            Spacer()
        }
    }
}

extension PlayTimeView {
    /// 초 단위의 double 값을 MM:SS 형태로 만들어주는 함수
    private func formattedTime(_ time: Double) -> String {
        let timeInt = Int(time)
        
        let minutes = timeInt / 60
        let seconds = timeInt % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
