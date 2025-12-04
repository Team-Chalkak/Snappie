//
//  Guide.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

import Foundation
import SwiftData
import UIKit

extension SchemaV2.Guide: Hashable {
    public static func == (lhs: SchemaV2.Guide, rhs: SchemaV2.Guide) -> Bool { lhs.clipID == rhs.clipID }
    public func hash(into hasher: inout Hasher) { hasher.combine(clipID) }
}
