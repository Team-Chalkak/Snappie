//
//  Project.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

import Foundation
import SwiftData

@Model
class Project: Identifiable {
    @Attribute(.unique) var id: String
    var guide: Guide?
    var clipList: [Clip]

    init(
        id: String = UUID().uuidString,
        guide: Guide? = nil,
        clipList: [Clip] = []
    ) {
        self.id = id
        self.guide = guide
        self.clipList = clipList
    }
}
