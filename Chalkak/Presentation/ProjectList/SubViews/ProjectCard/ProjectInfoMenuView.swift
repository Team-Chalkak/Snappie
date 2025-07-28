//
//  ProjectInfoMenuView.swift
//  Chalkak
//
//  Created by 석민솔 on 7/28/25.
//

import SwiftUI

// 프로젝트 정보랑 메뉴 떠있는 이미지 하단부 서브뷰
struct ProjectInfoMenuView: View {
    // MARK: input properties
    let isCurrentProject: Bool
    let projectTitle: String
    let isSeen: Bool
    let timeCreated: Date
    // actions
    let moveToProjectEdit: () -> Void
    let showEditTitleAlert: () -> Void
    let showDeleteProjectAlert: () -> Void
    
    // MARK: body
    var body: some View {
        HStack {
            // text infos
            ProjectInfoTextView(
                isCurrentProject: isCurrentProject,
                projectTitle: projectTitle,
                isSeen: isSeen,
                timeCreated: timeCreated
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if !isCurrentProject {
                    moveToProjectEdit()
                }
            }
            
            Spacer()
            
            // ellipsis menu
            ProjectCardMenuView(
                isCurrentProject: isCurrentProject,
                moveToProjectEdit: moveToProjectEdit,
                showEditTitleAlert: showEditTitleAlert,
                showDeleteProjectAlert: showDeleteProjectAlert
            )
        }
    }
}

#Preview {
    ProjectInfoMenuView(
        isCurrentProject: false,
        projectTitle: "제목",
        isSeen: true,
        timeCreated: Date(),
        moveToProjectEdit: {
            print("moveToProjectEdit")
        },
        showEditTitleAlert: {},
        showDeleteProjectAlert: {}
    )
    .background(
        Color.gray.opacity(0.7)
    )
    .frame(width: 173)
}
