//
//  Guide.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

import Foundation
import SwiftData
import UIKit

extension SchemaV3.Guide: Hashable {
    public static func == (lhs: SchemaV3.Guide, rhs: SchemaV3.Guide) -> Bool { lhs.clipID == rhs.clipID }
    public func hash(into hasher: inout Hasher) { hasher.combine(clipID) }
}
