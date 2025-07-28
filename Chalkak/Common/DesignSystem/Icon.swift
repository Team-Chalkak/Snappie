//
//  Icon.swift
//  Chalkak
//
//  Created by 석민솔 on 7/22/25.
//

import SwiftUI

/// 아이콘의 종류를 정의하는 enum
///
/// - rawValue와 asset이름이 일치하도록 설계해서 Image 이름을 쓸 때  `.rawValue`로 접근할 수 있도록 했습니다.
enum Icon: String {
    // custom
    case flashAuto
    case flashOff
    case flashOn
    case grid
    case level
    case timer3sec
    case timer5sec
    case timer10sec
    case timerOff
    case ellipsis
    
    // common
    case arrowBackward
    case arrowForward
    case blank
    case chevronBackward
    case chevronDown
    case chevronForward
    case chevronUp
    case conversion
    case pauseFill
    case playFill
    case dismiss
    case silhouette
}

/// 아이콘의 크기 
enum IconScale: CGFloat {
    case small = 16
    case medium = 18
    case large = 20
    case xlarge = 24
}
