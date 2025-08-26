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
                BoundingBoxView(shootState: .firstShoot)
                    .navigationDestination(for: Path.self) { path in
                        switch path {
                        case .clipEdit(let url, let state, let cameraSetting, let timeStampedTiltList):
                            ClipEditView(
                                clipURL: url,
                                shootState: state,
                                cameraSetting: cameraSetting,
                                timeStampedTiltList: timeStampedTiltList
                            )
                            
                        case .overlay(let clip, let cameraSetting):
                            OverlayView(clip: clip, cameraSetting: cameraSetting)
                                .toolbar(.hidden, for: .navigationBar)

                        case .camera(let state):
                            BoundingBoxView(shootState: state)
                                .toolbar(.hidden, for: .navigationBar)
                            
                            
                        case .projectPreview:
                            ProjectPreviewView()
                        
                        case .projectEdit(let projectID):
                            ProjectEditView(projectID: projectID)
                                .toolbar(.hidden, for: .navigationBar)
                            
                        case .projectList:
                            ProjectListView()
                        }
                        
                    }
            }
            .environmentObject(coordinator)
        }
        .modelContainer(sharedContainer)
    }
}
