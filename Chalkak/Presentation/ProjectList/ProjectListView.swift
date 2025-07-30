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
                    EmptyProjectView()
                }
                else {
                    NonEmptyProjectView(viewModel: viewModel)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .snappieAlert(isPresented: $viewModel.showProjectDeletedAlert, message: "프로젝트 삭제됨", showImage: false)
    }
}

#Preview {
    ProjectListView()
}
