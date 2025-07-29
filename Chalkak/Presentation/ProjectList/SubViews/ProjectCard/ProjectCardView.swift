//
//  ProjectCardView.swift
//  Chalkak
//
//  Created by 석민솔 on 7/28/25.
//

import SwiftUI

/// 프로젝트 카드 셀 컴포넌트뷰
struct ProjectCardView: View {
    // MARK: input properties
    /// 촬영중인 프로젝트면 disable하기위한 Bool 변수
    let isCurrentProject: Bool
    
    /// 커버 이미지입니다.
    let image: Image
    /// 프로젝트의 총길이(sec 단위)를 넘겨주시면 여기서 계산해서 쓰도록 하겠습니다
    let time: Double
    
    /// 제목
    let projectTitle: String
    
    /// 조회가 됐던 프로젝트인지 확인용 변수
    let isChecked: Bool
    
    /// 날짜
    let timeCreated: Date
    
    // MARK: actions properties
    /// 프로젝트 편집 화면 넘어가기
    let moveToProjectEdit: () -> Void
    /// 삭제 액션 클로저
    let deleteProject: () -> Void
    /// 프로젝트 이름 수정 클로저
    let editProjectTitle: (String) -> Void
    
    // MARK: State properties
    @State var showEditTitleAlert: Bool = false
    @State var showDeleteProjectAlert: Bool = false
    @State var titleToChange: String = ""
    
    // MARK: body
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 이미지 썸네일
            ProjectCardCoverImageView(
                isCurrentProject: isCurrentProject,
                image: image,
                time: time,
                moveToProjectEdit: moveToProjectEdit
            )
            
            // 썸네일 하단부
            ProjectInfoMenuView(
                isCurrentProject: isCurrentProject,
                projectTitle: projectTitle,
                isChecked: isChecked,
                timeCreated: timeCreated,
                moveToProjectEdit: moveToProjectEdit,
                showEditTitleAlert: {
                    showEditTitleAlert.toggle()
                },
                showDeleteProjectAlert: {
                    showDeleteProjectAlert.toggle()
                }
            )
        }
        .alert(
            //TODO: 핀의 커스템 알럿으로 대체
            "프로젝트를 삭제하시겠습니까?",
            isPresented: $showDeleteProjectAlert,
            actions: {
                Button("취소", role: .cancel) { }
                
                Button("삭제", role: .destructive) {
                    // 프로젝트 삭제
                    deleteProject()
                }
            },
            message: {
                Text("프로젝트와 클립이 모두 삭제됩니다.")
            }
        )
        .alert(
            "프로젝트 이름 변경",
            isPresented: $showEditTitleAlert,
            actions: {
                TextField(projectTitle, text: $titleToChange)
                    .onChange(of: titleToChange) { oldValue, newValue in
                        // 13글자 입력 제한
                        if newValue.count > 13 {
                            titleToChange = String(newValue.prefix(13))
                        }
                    }
                
                Button("취소") { }
                
                Button("저장") {
                    // 이름 변경 반영
                    editProjectTitle(titleToChange)
                }
            },
            message: {
                Text("프로젝트와 클립이 모두 삭제됩니다.")
            }
        )
    }
}

#Preview {
    ZStack {
        SnappieColor.darkHeavy
        
        VStack(spacing: 20) {
            ProjectCardView(
                isCurrentProject: false,
                image: Image("pinggu"),
                time: 140,
                projectTitle: "Project Title",
                isChecked: true,
                timeCreated: Date(),
                moveToProjectEdit: {
                    print("moveToProjectEdit")
                },
                deleteProject: {},
                editProjectTitle: { _ in }
            )
            .frame(width: 200)
            
            ProjectCardView(
                isCurrentProject: true,
                image: Image("pinggu"),
                time: 140,
                projectTitle: "Project Title",
                isChecked: true,
                timeCreated: Date(),
                moveToProjectEdit: {
                    print("moveToProjectEdit")
                },
                deleteProject: {},
                editProjectTitle: { _ in }
            )
            .frame(width: 200)
        }
    }
}
