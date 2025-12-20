//
//  ChalkakApp.swift
//  Chalkak
//
//  Created by 배현진 on 7/11/25.
//

import AdSupport
import AppTrackingTransparency
import FirebaseCore
import SwiftData
import SwiftUI

@main
struct ChalkakApp: App {
    let sharedContainer: ModelContainer

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var coordinator = Coordinator()
    
    init() {
        let config = ModelConfiguration()
        self.sharedContainer = try! ModelContainer(
            for: Clip.self, Guide.self, Project.self,
            configurations: config
        )
        SwiftDataManager.shared.configure(container: sharedContainer)
        
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
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    print("Authorized")
                    print("IDFA = \(ASIdentifierManager.shared().advertisingIdentifier)")
                    FirebaseApp.configure()
                case .denied:
                    print("Denied")
                case .notDetermined:
                    print("Not Determined")
                case .restricted:
                    print("Restricted")
                @unknown default:
                    print("Unknow")
                }
            }
        }
        return true
    }
}
