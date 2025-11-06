//
//  CameraSetting.swift
//  Chalkak
//
//  Created by 배현진 on 7/19/25.
//

import Foundation
import SwiftData

extension SchemaV2.CameraSetting: Hashable {
    static func == (lhs: CameraSetting, rhs: CameraSetting) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
