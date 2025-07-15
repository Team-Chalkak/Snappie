//
//  TimerOptions.swift
//  Chalkak
//
//  Created by 정종문 on 7/15/25.
//

enum TimerOptions: Int, CaseIterable {
    case off = 0
    case three = 3
    case five = 5
    case ten = 10

    var displayText: String {
        switch self {
        case .off: return "해제"
        case .three: return "3초"
        case .five: return "5초"
        case .ten: return "10초"
        }
    }
}
