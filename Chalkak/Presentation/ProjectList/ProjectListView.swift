//
//  ProjectListView.swift
//  Chalkak
//
//  Created by 석민솔 on 7/28/25.
//

import SwiftUI

/// 프로젝트 리스트 메인뷰
struct ProjectListView: View {
    // MARK: properties

    // property wrappers
    @StateObject var viewModel = ProjectListViewModel()
    @EnvironmentObject private var coordinator: Coordinator

    let gridItems: [GridItem] = [
        GridItem(spacing: 15, alignment: .trailing),
        GridItem(spacing: 15, alignment: .leading)
    ]

    // MARK: body

    var body: some View {
        ZStack {
            SnappieColor.darkHeavy
                .ignoresSafeArea()

            VStack {
                Button {
                    coordinator.push(.startProject)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("새 프로젝트")
                    }.foregroundStyle(SnappieColor.labelDarkNormal)
                }
                // 컨텐츠
                if viewModel.projects.isEmpty {
                    EmptyProjectView()
                }
                else {
                    NonEmptyProjectView(viewModel: viewModel)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .snappieAlert(isPresented: $viewModel.showProjectDeletedAlert, message: "프로젝트 삭제됨", showImage: false)
        .onAppear {
            viewModel.fetchProjects()

            // 삭제할 프로젝트가 있는지 확인
            if let projectIDToDelete = UserDefaults.standard.string(forKey: "ProjectToDelete"),
               let projectToDelete = viewModel.projects.first(where: { $0.id == projectIDToDelete })
            {
                UserDefaults.standard.removeObject(forKey: "ProjectToDelete")
                viewModel.deleteProject(projectToDelete)
            }
        }
    }
}

#Preview {
    ProjectListView()
}
