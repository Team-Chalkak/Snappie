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
    let sharedContainer: ModelContainer

    @StateObject private var coordinator = Coordinator()
    
    init() {
        let config = ModelConfiguration()
        self.sharedContainer = try! ModelContainer(
            for: Clip.self, Guide.self, Project.self,
            configurations: config
        )
        SwiftDataManager.shared.configure(container: sharedContainer)
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $coordinator.path) {
                BoundingBoxView(guide: nil, isFirstShoot: true)
                    .navigationDestination(for: Path.self) { path in
                        switch path {
                        case .clipEdit(let url, let isFirstShoot, let guide, let cameraSetting, let timeStampedTiltList):
                            ClipEditView(
                                clipURL: url,
                                isFirstShoot: isFirstShoot,
                                guide: guide,
                                cameraSetting: cameraSetting,
                                timeStampedTiltList: timeStampedTiltList
                            )

                        case .overlay(let clip, let isFrontCamera):
                            OverlayView(
                                clip: clip,
                                isFrontCamera: isFrontCamera
                            )

                        case .boundingBox(let guide, let isFirstShoot):
                            BoundingBoxView(guide: guide, isFirstShoot: isFirstShoot)
                                .toolbar(.hidden, for: .navigationBar)
                            
                            
                        case .projectPreview(finalVideoURL: let finalVideoURL):
                            ProjectPreviewView(finalVideoURL: finalVideoURL)
                        }
                    }
            }
            .environmentObject(coordinator)
        }
        .modelContainer(sharedContainer)
    }
}
