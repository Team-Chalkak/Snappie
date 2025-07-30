//
//  ProjectListViewModel.swift
//  Chalkak
//
//  Created by 석민솔 on 7/28/25.
//

import Foundation
import SwiftUI
import SwiftData

/// 프로젝트 리스트 뷰모델
@MainActor
final class ProjectListViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var showProjectDeletedAlert: Bool = false

    init() {
        fetchProjects()
    }

    /// 모든 프로젝트 중 guide가 있는 것만 가져오기
    func fetchProjects() {
        let allProjects = SwiftDataManager.shared.fetchAllProjects()
        self.projects = allProjects.filter { $0.guide != nil }
    }
    
    /// 현재 유저디폴트의 currentProject인가 확인
    func isCurrentProject(_ project: Project) -> Bool {
        if let currentProjectID = UserDefaults.standard.string(forKey: "currentProjectID") {
            return project.id == currentProjectID
        } else {
            return false
        }
    }
    
    /// 프로젝트 삭제
    func deleteProject(_ project: Project) {
        SwiftDataManager.shared.deleteProject(project)
        fetchProjects()
        showProjectDeletedAlert = true
    }
    
    /// 프로젝트 이름 변경
    func editProjectTitle(project: Project, newTitle: String) {
        SwiftDataManager.shared.updateProjectTitle(project: project, newTitle: newTitle)
        fetchProjects()
    }
}
