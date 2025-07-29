//
//  ProjectListViewModel.swift
//  Chalkak
//
//  Created by 석민솔 on 7/28/25.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
final class ProjectListViewModel: ObservableObject {
    @Published var projects: [Project] = []

    init() {
        fetchProjects()
    }

    /// 모든 프로젝트 가져오기
    func fetchProjects() {
        projects = SwiftDataManager.shared.fetchAllProjects()
    }
    
    /// 현재 유저디폴트의 currentProject인가
    func isCurrentProject(_ project: Project) -> Bool {
        if let currentProjectID = UserDefaults.standard.string(forKey: "currentProjectID") {
            return project.id == currentProjectID
        } else {
            return false
        }
    }
}
