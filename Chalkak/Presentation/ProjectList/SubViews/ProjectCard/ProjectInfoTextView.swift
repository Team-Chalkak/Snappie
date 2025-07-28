//
//  ProjectInfoTextView.swift
//  Chalkak
//
//  Created by 석민솔 on 7/28/25.
//

import SwiftUI

/// 프로젝트 제목, 날짜를 보여주는 텍스트 위주의 뷰
struct ProjectInfoTextView: View {
    // MARK: input properties
    /// 촬영중인 프로젝트면 disable하기위한 Bool 변수
    let isCurrentProject: Bool
    
    /// 제목
    let projectTitle: String
    /// 조회가 됐던 프로젝트인지 확인용 변수
    let isSeen: Bool
    /// 날짜
    let timeCreated: Date
    
    // MARK: computed proeprties
    var timeCreatedString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: timeCreated)
    }
    
    // MARK: body
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 2) {
                // 조회가 되면 없어지는 빨간 원
                if !isCurrentProject && !isSeen {
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundStyle(Color.redRecording)
                }
                
                // 제목
                Text(projectTitle)
                    .font(SnappieFont.style(.proLabel2))
                    .foregroundStyle(
                        isCurrentProject
                        ? SnappieColor.labelPrimaryDisable
                        : SnappieColor.labelPrimaryNormal
                    )
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            // 날짜
            Text(timeCreatedString)
                .font(SnappieFont.style(.proCaption1))
                .foregroundStyle(SnappieColor.labelDarkInactive)
        }
    }
}

#Preview {
    ProjectInfoTextView(
        isCurrentProject: false,
        projectTitle: "Project title",
        isSeen: false,
        timeCreated: Date()
    )
    .frame(width: 300, height: 300)
    .background(
        Color.black
    )
}
