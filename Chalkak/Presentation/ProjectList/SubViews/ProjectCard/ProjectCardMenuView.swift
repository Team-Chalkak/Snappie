//
//  ProjectCardMenuView.swift
//  Chalkak
//
//  Created by 석민솔 on 7/28/25.
//

import SwiftUI

/// 메뉴만 보여주는 뷰
struct ProjectCardMenuView: View {
    // MARK: input properties
    let isCurrentProject: Bool
    let moveToProjectEdit: () -> Void
    let showEditTitleAlert: () -> Void
    let showDeleteProjectAlert: () -> Void
    
    // MARK: body
    var body: some View {
        Menu {
            Button("프로젝트 편집") {
                moveToProjectEdit()
            }
            
            Button(
                "이름 변경",
                systemImage: "square.and.pencil",
                role: .none,
                action: showEditTitleAlert
            )
            
            Button(
                "삭제",
                systemImage: "trash",
                role: .destructive,
                action: showDeleteProjectAlert
            )
        } label: {
            IconView(iconType: .ellipsis, scale: .small)
                .foregroundStyle(
                    isCurrentProject
                    ? SnappieColor.labelPrimaryDisable
                    : SnappieColor.labelPrimaryNormal
                )
                .frame(width: 26, height: 26, alignment: .topTrailing)
                .contentShape(Rectangle())
        }
        .disabled(isCurrentProject)

    }
}

#Preview {
    ProjectCardMenuView(
        isCurrentProject: false,
        moveToProjectEdit: {},
        showEditTitleAlert: {},
        showDeleteProjectAlert: {}
    )
}
