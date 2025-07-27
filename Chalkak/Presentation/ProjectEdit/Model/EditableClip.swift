//
//  EditableClip.swift
//  Chalkak
//
//  Created by 배현진 on 7/24/25.
//

import Foundation

struct EditableClip: Identifiable {
    let id: String
    let url: URL
    let originalDuration: Double
    
    // 트리밍 범위
    var startPoint: Double
    var endPoint: Double
    
    // 트리밍 모드 활성화 플래그
    var isTrimming: Bool = false
    
    // 계산 프로퍼티: 실제 플레이 타임
    var trimmedDuration: Double {
        max(0, endPoint - startPoint)
    }
}
