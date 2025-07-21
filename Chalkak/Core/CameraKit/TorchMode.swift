//
//  TorchMode.swift
//  Chalkak
//
//  Created on 2025-07-21.
//

import Foundation

enum TorchMode: CaseIterable {
    case off, on, auto
    
    mutating func toggle() {
        switch self {
        case .off: self = .on
        case .on: self = .auto  
        case .auto: self = .off
        }
    }
    
    var iconName: String {
        switch self {
        case .off: return "bolt.slash"
        case .on: return "bolt.fill"
        case .auto: return "bolt.badge.automatic"
        }
    }
}