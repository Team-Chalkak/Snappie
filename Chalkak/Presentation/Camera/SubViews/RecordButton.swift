//
//  RecordButton.swift
//  Chalkak
//
//  Created by 정종문 on 7/25/25.
//

import SwiftUI

struct RecordButton: View {
    let isRecording: Bool
    let isTimerRunning: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(lineWidth: 3)
                    .frame(width: 74, height: 74)
                    .foregroundColor(.white)
                
                // 내부 상태별 아이콘
                Group {
                    if isTimerRunning {
                        cancelIcon
                    } else if !isRecording {
                        recordIcon
                    } else {
                        stopIcon
                    }
                }
            }
        }
    }
    
    // 상태별 아이콘 형태

    private var cancelIcon: some View {
        Image(systemName: "xmark")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
    }
    
    private var recordIcon: some View {
        Circle()
            .fill(SnappieColor.redRecording)
            .frame(width: 58, height: 58)
    }
    
    private var stopIcon: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(SnappieColor.redRecording)
            .frame(width: 32, height: 32)
    }
}
