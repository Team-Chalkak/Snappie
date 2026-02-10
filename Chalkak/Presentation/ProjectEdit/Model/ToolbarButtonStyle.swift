//
//  ToolbarButtonStyle.swift
//  Chalkak
//
//  Created by 석민솔 on 12/29/25.
//

import SwiftUI

enum ToolbarButtonStyle {
    case editClip
    case editGuide
    case deleteClip
}

extension ToolbarButtonStyle {
    var label: LocalizedStringKey {
        switch self {
        case .editClip:
            "장면 다듬기"
        case .editGuide:
            "가이드 수정"
        case .deleteClip:
            "장면 삭제"
        }
    }
}
