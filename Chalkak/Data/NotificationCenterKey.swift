//
//  NotificationCenterKey.swift
//  Chalkak
//
//  Created by 석민솔 on 2/10/26.
//

import Foundation

enum NotificationCenterKey: String {
    case ClipReorderingStateChanged
    
    var userInfoKey: String {
        switch self {
        case .ClipReorderingStateChanged:
            "isReordering"
        }
    }
}
