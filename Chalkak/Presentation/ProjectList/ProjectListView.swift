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
                // navigation
                SnappieNavigationBar(
                    navigationTitle: "프로젝트",
                    leftButtonType: .backward {
                        // TODO: 이전 버튼으로 돌아가는 버튼(네비게이션이 아니라 Full screen cover로 진행할 거라서 화면을 없애는 값을 바인딩으로 받아와야 할 것 같아요
                        coordinator.popLast()
                    },
                    rightButtonType: .none
                )
                
                // 컨텐츠
                if viewModel.projects.isEmpty {
                    emptyProjectView
                }
                else {
                    nonEmptyProjectView
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
}

extension ProjectListView {
    var emptyProjectView: some View {
        VStack {
            Spacer()
            
            Text("프로젝트가 비어 있어요.\n촬영을 시작하여 새 프로젝트를 만들어볼까요?")
                .multilineTextAlignment(.center)
                .font(SnappieFont.style(.proLabel1))
                .foregroundStyle(SnappieColor.labelPrimaryNormal)
                .lineSpacing(10)
            
            Spacer()
        }
    }
    
    var nonEmptyProjectView: some View {
        ScrollView {
            LazyVGrid(columns: gridItems, spacing: 16) {
                ForEach(viewModel.projects) { project in
                    ProjectCardView(
                        isCurrentProject: viewModel.isCurrentProject(project),
                        image: Image(uiImage: UIImage(data: project.coverImage ?? Data()) ?? UIImage()),
                        time: 150, //TODO: 전체 길이 계산해서 넣기
                        projectTitle: project.title,
                        isSeen: project.isChecked,
                        timeCreated: project.createdAt,
                        moveToProjectEdit: {
                            coordinator.push(.projectEdit)
                        },
                        deleteProject: {
                            viewModel.deleteProject(project)
                        },
                        editProjectTitle: { newTitle in
                            viewModel.editProjectTitle(project: project, newTitle: newTitle)
                        }                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    ProjectListView()
}
