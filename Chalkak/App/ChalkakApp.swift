//
//  ChalkakApp.swift
//  Chalkak
//
//  Created by 배현진 on 7/11/25.
//

import SwiftData
import SwiftUI

@main
struct ChalkakApp: App {
    var body: some Scene {
        WindowGroup {
            ClipEditView(clipURL: Bundle.main.url(forResource: "sample-video", withExtension: "mov")!, isFirstShoot: true)
        }
        .modelContainer(for: [Project.self, Clip.self, Guide.self])
    }
}


