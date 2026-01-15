//
//  Guide.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

import Foundation
import SwiftData
import UIKit

extension SchemaV4.Guide: Hashable {
    public static func == (lhs: SchemaV4.Guide, rhs: SchemaV4.Guide) -> Bool {
        lhs.clipID == rhs.clipID
    }
    
    public func hash(into hasher: inout Hasher) { hasher.combine(clipID) }
}
