//
//  SwiftDataManager.swift
//  Chalkak
//
//  Created by 배현진 on 7/15/25.
//

import Foundation
import SwiftData
import SwiftUI

/**
 SwiftData 사용을 편리하게 하기 위한 클래스
 
 `SwiftDataManager`는 SwiftData 사용을 편리하게 하기 위해 쿼리 메서드를 모아 관리합니다.
 
 ## 사용 예시
 ```
 @Published var clips: [Clip] = []
 
 func loadClips() {
     clips = SwiftDataManager.shared.fetchAllClips()
 }
 
 func createClip(
     videoURL: URL,
     startPoint: Double,
     endPoint: Double,
     tiltList: [TimeStampedTilt] = [],
     heightList: [TimeStampedHeight] = []
 ) {
     let _ = SwiftDataManager.shared.createClip(
         videoURL: videoURL,
         startPoint: startPoint,
         endPoint: endPoint,
         tiltList: tiltList,
         heightList: heightList
     )
     SwiftDataManager.shared.saveContext()
     loadClips()
 }
 
 func deleteClip(_ clip: Clip) {
     SwiftDataManager.shared.deleteClip(clip)
     SwiftDataManager.shared.saveContext()
     loadClips()
 }
 ```
 */

@MainActor
class SwiftDataManager {
    static let shared = SwiftDataManager()
    
    private var container: ModelContainer?
    var context: ModelContext {
        guard let container = container else {
            fatalError("ModelContainer가 아직 설정되지 않았습니다. configure(container:)를 먼저 호출하세요.")
        }
        return container.mainContext
    }

    private init() {}
    
    func configure(container: ModelContainer) {
        self.container = container
    }

    // MARK: - Project
    
    /// `Project` 생성
    func createProject(
        id: String,
        guide: Guide? = nil,
        clips: [Clip] = [],
        cameraSetting: CameraSetting? = nil,
        title: String? = nil,
        referenceDuration: Double? = nil,
        isChecked: Bool = false,
        coverImage: Data? = nil,
        createdAt: Date = Date()
    ) -> Project {
        let project = Project(
            id: id,
            guide: guide,
            clipList: clips,
            cameraSetting: cameraSetting,
            title: title ?? "",
            referenceDuration: referenceDuration,
            isChecked: isChecked,
            coverImage: coverImage,
            createdAt: createdAt
        )
        context.insert(project)
        return project
    }

    // TODO: - 프로젝트 단의 관리 시작 시점에 구현 (Berry)
    //    func fetchAllProjects() -> [Project] {
    //    }
    
    /// `Project` id 이용해 조회
    func fetchProject(byID id: String) -> Project? {
        let predicate = #Predicate<Project> { $0.id == id }
        let descriptor = FetchDescriptor<Project>(predicate: predicate)
        return try? context.fetch(descriptor).first
    }

    /// `Project` 삭제
    func deleteProject(_ project: Project) {
        context.delete(project)
        saveContext()
    }
    
    /// 모든 프로젝트 조회
    func fetchAllProjects() -> [Project] {
        let descriptor = FetchDescriptor<Project>()
        return (try? context.fetch(descriptor)) ?? []
    }
    
    /// 프로젝트에 'coverImage' 업데이트
    func updateProjectCoverImage(projectID: String, coverImage: UIImage) {
        guard let project = fetchProject(byID: projectID) else {
            print("해당 Project(\(projectID))를 찾을 수 없습니다.")
            return
        }

        project.coverImage = coverImage.jpegData(compressionQuality: 0.8)
        saveContext()
    }
    
    /// 프로젝트 '타이틀' 변경(업데이트)
    func updateProjectTitle(project: Project, newTitle: String) {
        project.title = newTitle
        saveContext()
    }
    
    /// 확인하지 않은 프로젝트 조회
    func getUncheckedProjects() -> [Project] {
        let predicate = #Predicate<Project> { $0.isChecked == false }
        let descriptor = FetchDescriptor<Project>(predicate: predicate)
        return (try? context.fetch(descriptor)) ?? []
    }
    
    /// 뱃지 표시용 확인하지 않은 프로젝트 조회 (guide가 있고, 현재 촬영 중이 아닌 것)
    func getUncheckedProjectsForBadge() -> [Project] {
        let predicate = #Predicate<Project> { project in
            project.isChecked == false && project.guide != nil
        }
        let descriptor = FetchDescriptor<Project>(predicate: predicate)
        let uncheckedProjects = (try? context.fetch(descriptor)) ?? []
        
        // 현재 촬영 중인 프로젝트 제외
        guard let currentProjectID = UserDefaults.standard.string(forKey: "currentProjectID") else {
            return uncheckedProjects
        }
        return uncheckedProjects.filter { $0.id != currentProjectID }
    }
    
    /// 프로젝트 확인 상태 업데이트
    func markProjectAsChecked(projectID: String) {
        guard let project = fetchProject(byID: projectID) else {
            print("해당 Project(\(projectID))를 찾을 수 없습니다.")
            return
        }
        
        project.isChecked = true
        saveContext()
        
        // 뱃지 상태 최신화
        DispatchQueue.main.async {
            try? self.context.save()
        }
    }
    
    // MARK: - Clip

    /// `Clip` 생성: Clip 객체 데이터로
    func createClip(
        id: String,
        videoURL: URL,
        originalDuration: Double,
        startPoint: Double = 0,
        endPoint: Double,
        tiltList: [TimeStampedTilt] = []
    ) -> Clip? {
        // URL 유효성 검증
        guard FileManager.isValidVideoFile(at: videoURL) else {
            print("createClip: 유효하지 않은 비디오 파일 URL: \(videoURL)")
            return nil
        }
        
        let clip = Clip(
            id: id,
            videoURL: videoURL,
            originalDuration: originalDuration,
            startPoint: startPoint,
            endPoint: endPoint,
            tiltList: tiltList
        )
        context.insert(clip)
        return clip
    }
    
    /// `Clip` 생성: Clip 객체로
    func createClip(clip: Clip) -> Clip? {
        // URL 유효성 검증
        guard FileManager.isValidVideoFile(at: clip.videoURL) else {
            print("createClip: 유효하지 않은 비디오 파일 URL: \(clip.videoURL)")
            return nil
        }
        
        context.insert(clip)
        return clip
    }

    /// `Clip` 가져오기
    func fetchClip(byID id: String) -> Clip? {
        let predicate = #Predicate<Clip> { $0.id == id }
        let descriptor = FetchDescriptor<Clip>(predicate: predicate)
        return try? context.fetch(descriptor).first
    }

    /// `Clip` 삭제하기
    func deleteClip(_ clip: Clip) {
        context.delete(clip)
    }

    // MARK: - Guide

    /// `Guide` 생성
    func createGuide(
        clipID: String,
        boundingBoxes: [BoundingBoxInfo],
        outlineImage: UIImage,
        cameraTilt: Tilt,
        cameraHeight: Float
    ) -> Guide {
        let guide = Guide(
            clipID: clipID,
            boundingBoxes: boundingBoxes,
            outlineImage: outlineImage,
            cameraTilt: cameraTilt,
            cameraHeight: cameraHeight
        )
        context.insert(guide)
        return guide
    }

    /// `Guide` 저장하고 Project에 연결
    func saveGuideToProject(projectID: String, guide: Guide) {
        guard let project = fetchProject(byID: projectID) else {
            print("해당 ID(\(projectID))의 Project를 찾을 수 없습니다.")
            return
        }
        
        project.guide = guide
        context.insert(guide) // guide도 context에 삽입
        saveContext()
    }
    
    /// `Guide` 가져오기
    func fetchGuide(forClipID clipID: String) -> Guide? {
        let predicate = #Predicate<Guide> { $0.clipID == clipID }
        let descriptor = FetchDescriptor<Guide>(predicate: predicate)
        return try? context.fetch(descriptor).first
    }

    /// `Guide` 삭제하기
    func deleteGuide(_ guide: Guide) {
        context.delete(guide)
    }
    
    // MARK: - CameraSetting
    
    /// `CameraSetting` 생성
    func createCameraSetting(
        zoomScale: CGFloat,
        isGridEnabled: Bool,
        isFrontPosition: Bool,
        timerSecond: Int
    ) -> CameraSetting {
        let setting = CameraSetting(
            zoomScale: zoomScale,
            isGridEnabled: isGridEnabled,
            isFrontPosition: isFrontPosition,
            timerSecond: timerSecond
        )
        context.insert(setting)
        return setting
    }

    // MARK: - Save & Rollback

    /// Context 저장하기 - 변경사항 반영
    func saveContext() {
        do {
            try context.save()
        } catch {
            print("저장 실패: \(error)")
        }
    }
}
