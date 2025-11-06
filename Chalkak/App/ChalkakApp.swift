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
        do {
          self.sharedContainer = try ModelContainer(
            for: SchemaV2.Clip.self, SchemaV2.Guide.self, SchemaV2.Project.self, SchemaV2.CameraSetting.self,
            migrationPlan: MigrationPlan.self
          )
        } catch {
          assertionFailure("ModelContainer init error: \(error)")
          fatalError()
        }
        
        SwiftDataManager.shared.configure(container: sharedContainer)
        
        backfillGuideWasMirroredIfNeeded(container: sharedContainer)
        
        Task { @MainActor in
            SwiftDataManager.shared.cleanupAllTempProjects()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $coordinator.path) {
                BoundingBoxView(shootState: .firstShoot)
                    .navigationDestination(for: Path.self) { path in
                        switch path {
                        case .clipEdit(let url, let state, let cameraSetting, let cameraManager, let timeStampedTiltList):
                            ClipEditView(
                                clipURL: url,
                                shootState: state,
                                cameraSetting: cameraSetting,
                                cameraManager: cameraManager,
                                timeStampedTiltList: timeStampedTiltList
                            )
                            
                        case .overlay(let clip, let cameraSetting, let cameraManager):
                            OverlayView(clip: clip, cameraSetting: cameraSetting, cameraManager: cameraManager)
                                .toolbar(.hidden, for: .navigationBar)

                        case .camera(let state):
                            BoundingBoxView(shootState: state)
                                .toolbar(.hidden, for: .navigationBar)
                            
                            
                        case .projectPreview:
                            ProjectPreviewView()
                        
                        case .projectEdit(let projectID, let newClip):
                            ProjectEditView(projectID: projectID, newClip: newClip)
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
    
    private func backfillGuideWasMirroredIfNeeded(container: ModelContainer) {
        let flagKey = "didBackfill_GuideWasMirroredAtCapture_v2_0_0"
        guard !UserDefaults.standard.bool(forKey: flagKey) else { return }

        let context = ModelContext(container)

        do {
            // 아직 false인 것만 대상(초기 기본값 false)
            var fd = FetchDescriptor<SchemaV2.Guide>()
            fd.predicate = #Predicate<SchemaV2.Guide> { $0.wasMirroredAtCapture == false }
            let guides = try context.fetch(fd)

            // 프로젝트 미리 로드해서 메모리 매칭
            let projects = try context.fetch(FetchDescriptor<SchemaV2.Project>())

            for guide in guides {
                if let project = projects.first(where: { $0.guide.clipID == guide.clipID }),
                   let cam = project.cameraSetting,
                   cam.isFrontPosition
                {
                    guide.wasMirroredAtCapture = true
                }
            }

            try context.save()
            UserDefaults.standard.set(true, forKey: flagKey)
        } catch {
            print("Backfill failed: \(error)")
        }
    }
}
