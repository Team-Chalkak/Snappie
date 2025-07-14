//
//  Project.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

import Foundation
import SwiftData

/// A project that groups a guide and a list of video clips.
@Model
class Project: Identifiable {
    /// A unique identifier for the project.
    @Attribute(.unique) var id: String
    
    /// The visual guide associated with this project.
    /// Deleted automatically if the project is deleted.
    @Relationship(deleteRule: .cascade) var guide: Guide?
    
    /// A list of clips included in this project.
    /// All clips are deleted when the project is deleted.
    @Relationship(deleteRule: .cascade) var clipList: [Clip]

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
