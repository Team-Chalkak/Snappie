//
//  EditableClip.swift
//  Chalkak
//
//  Created by 배현진 on 7/24/25.
//

import Foundation
import UIKit

struct EditableClip: Identifiable {
    let id: String
    let url: URL
    let originalDuration: Double

    // 트리밍 범위
    var startPoint: Double
    var endPoint: Double

    // 트리밍 모드 활성화 플래그
    var isTrimming: Bool = false

    // 미리 생성된 썸네일 배열
    let thumbnails: [UIImage]

    // 실제 재생되는 길이
    var trimmedDuration: Double {
        max(0, endPoint - startPoint)
    }
}
