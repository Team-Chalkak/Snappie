//
//  NonEmptyProjectView.swift
//  Chalkak
//
//  Created by Youbin on 7/29/25.
//

import SwiftUI

/// 프로젝트가 존재할 때 보여지는 리스트 뷰
struct NonEmptyProjectView: View {
    @ObservedObject var viewModel: ProjectListViewModel
    @EnvironmentObject private var coordinator: Coordinator
    
    private let gridItems: [GridItem] = [
        GridItem(spacing: 15, alignment: .trailing),
        GridItem(spacing: 15, alignment: .leading)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridItems, spacing: 16) {
                ForEach(viewModel.projects) { project in
                    ProjectCardView(
                        isCurrentProject: viewModel.isCurrentProject(project),
                        image: Image(uiImage: UIImage(data: project.coverImage ?? Data()) ?? UIImage()),
                        time: 150, // TODO: 전체 길이 계산해서 넣기
                        projectTitle: project.title,
                        isChecked: project.isChecked,
                        timeCreated: project.createdAt,
                        moveToProjectEdit: {
                            coordinator.push(.projectEdit)
                        },
                        deleteProject: {
                            viewModel.deleteProject(project)
                        },
                        editProjectTitle: { newTitle in
                            viewModel.editProjectTitle(project: project, newTitle: newTitle)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
