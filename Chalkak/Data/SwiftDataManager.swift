//
//  SwiftDataManager.swift
//  Chalkak
//
//  Created by 배현진 on 7/15/25.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class SwiftDataManager {
    static let shared = SwiftDataManager()
    
    private let container: ModelContainer
    var context: ModelContext { container.mainContext }

    private init() {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            self.container = try ModelContainer(
                for: Clip.self, Guide.self, Project.self,
                configurations: config
            )
        } catch {
            fatalError("ModelContainer 초기화 실패: \(error)")
        }
    }

    // MARK: - Project
    
    func createProject(guide: Guide? = nil, clips: [Clip] = []) -> Project {
        let newProject = Project(guide: guide, clipList: clips)
        context.insert(newProject)
        return newProject
    }

    // TODO: - 프로젝트 단의 관리 시작 시점에 구현 (Berry)
    //    func fetchAllProjects() -> [Project] {
    //    }

    func deleteProject(_ project: Project) {
        context.delete(project)
    }

    // MARK: - Clip

    func createClip(
        videoURL: URL,
        startPoint: Double = 0,
        endPoint: Double,
        tiltList: [TimeStampedTilt] = [],
        heightList: [TimeStampedHeight] = []
    ) -> Clip {
        let clip = Clip(
            videoURL: videoURL,
            startPoint: startPoint,
            endPoint: endPoint,
            tiltList: tiltList,
            heightList: heightList
        )
        context.insert(clip)
        return clip
    }

    func fetchClip(byID id: String) -> Clip? {
        let predicate = #Predicate<Clip> { $0.id == id }
        let descriptor = FetchDescriptor<Clip>(predicate: predicate)
        return try? context.fetch(descriptor).first
    }

    func deleteClip(_ clip: Clip) {
        context.delete(clip)
    }

    // MARK: - Guide

    func createGuide(
        clipID: String,
        bBoxPosition: CGPoint,
        bBoxScale: CGFloat,
        outlineImage: UIImage,
        cameraTilt: Tilt,
        cameraHeight: Float
    ) -> Guide {
        let guide = Guide(
            clipID: clipID,
            bBoxPosition: bBoxPosition,
            bBoxScale: bBoxScale,
            outlineImage: outlineImage,
            cameraTilt: cameraTilt,
            cameraHeight: cameraHeight
        )
        context.insert(guide)
        return guide
    }

    func fetchGuide(forClipID clipID: String) -> Guide? {
        let predicate = #Predicate<Guide> { $0.clipID == clipID }
        let descriptor = FetchDescriptor<Guide>(predicate: predicate)
        return try? context.fetch(descriptor).first
    }

    func deleteGuide(_ guide: Guide) {
        context.delete(guide)
    }

    // MARK: - Save & Rollback

    func saveContext() {
        do {
            try context.save()
        } catch {
            print("저장 실패: \(error)")
        }
    }
}
