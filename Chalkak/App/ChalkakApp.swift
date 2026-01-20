//
//  ChalkakApp.swift
//  Chalkak
//
//  Created by 배현진 on 7/11/25.
//

import AdSupport
import AppTrackingTransparency
import FirebaseAnalytics
import FirebaseCore
import SwiftData
import SwiftUI
import TipKit

@main
struct ChalkakApp: App {
    let sharedContainer: ModelContainer

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var coordinator = Coordinator()
    @State private var permissionManager = PermissionManager()

    @AppStorage(UserDefaultKey.hasCompletedOnboarding)
    private var hasCompletedOnboarding: Bool = false

    init() {
        // TipKit 적용
        try? Tips.configure()

        do {
            self.sharedContainer = try ModelContainer(
                for: SchemaV4.Clip.self, SchemaV4.Guide.self, SchemaV4.Project.self, SchemaV4.CameraSetting.self,
                migrationPlan: MigrationPlan.self
            )
        } catch {
            assertionFailure("ModelContainer init error: \(error)")
            fatalError()
        }

        SwiftDataManager.shared.configure(container: sharedContainer)
        
        Task { @MainActor in
            SwiftDataManager.shared.cleanupAllTempProjects()
        }
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                NavigationStack(path: $coordinator.path) {
                    ProjectListView()
                        .navigationDestination(for: Path.self) { path in
                            switch path {
                            case .startProject:
                                StartProjectView()
                                    .toolbar(.hidden, for: .navigationBar)

                            case .clipEdit(let url, let state, let cameraSetting, let cameraManager, let timeStampedTiltList, let clipID):
                                ClipEditView(
                                    clipURL: url,
                                    shootState: state,
                                    cameraSetting: cameraSetting,
                                    cameraManager: cameraManager,
                                    timeStampedTiltList: timeStampedTiltList,
                                    clipID: clipID
                                )
                            case .guideSelect(let clip, let state, let cameraSetting, let cameraManager):
                                GuideSelectView(
                                    clip: clip,
                                    shootState: state,
                                    cameraSetting: cameraSetting,
                                    cameraManager: cameraManager)
                                     .toolbar(.hidden, for: .navigationBar)

                            case .overlay(let clip, let cameraSetting, let cameraManager, let selectedTimestamp):
                                OverlayView(clip: clip, cameraSetting: cameraSetting, cameraManager: cameraManager, selectedTimestamp: selectedTimestamp)
                                    .toolbar(.hidden, for: .navigationBar)

                            case .camera(let state):
                                BoundingBoxView(shootState: state)
                                    .toolbar(.hidden, for: .navigationBar)

                            case .projectPreview(let editableClips):
                                ProjectPreviewView(editableClips: editableClips)

                            case .projectEdit(let projectID, let newClip):
                                ProjectEditView(projectID: projectID, newClip: newClip)
                                    .toolbar(.hidden, for: .navigationBar)

                            case .projectList:
                                ProjectListView()
                            }
                        }
                }
                .environmentObject(coordinator)
                .environment(permissionManager)
                .sheet(isPresented: $permissionManager.showPermissionSheet) {
                    CameraPermissionSheet(permissionManager: permissionManager)
                }
            } else {
                OnboardingView(onComplete: {
                    hasCompletedOnboarding = true
                })
            }
        }
        .modelContainer(sharedContainer)
        .onChange(of: hasCompletedOnboarding) { oldValue, newValue in
            if oldValue == false && newValue == true {
                permissionManager.requestAndCheckPermissions()
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        FirebaseApp.configure()
        
        configureAnalyticsUserType()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    print("Authorized")
                    print("IDFA = \(ASIdentifierManager.shared().advertisingIdentifier)")
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
    
    private func configureAnalyticsUserType() {
        #if DEBUG
        Analytics.setUserProperty("internal traffic", forName: "traffic_type")
        
        #else
        if isTestFlight() {
            Analytics.setUserProperty("internal traffic", forName: "traffic_type")
        } else {
            Analytics.setUserProperty("external traffic", forName: "traffic_type")
        }
        #endif
    }

    private func isTestFlight() -> Bool {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else { return false }
        return receiptURL.lastPathComponent == "sandboxReceipt"
    }
}
