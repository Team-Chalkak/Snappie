//
//  ProjectCardCoverImageView.swift
//  Chalkak
//
//  Created by 석민솔 on 7/28/25.
//

import SwiftUI

/// 커버 이미지랑 프로젝트 시간 보여주는 부분
struct ProjectCardCoverImageView: View {
    // MARK: input properties
    /// 촬영중인 프로젝트면 disable하기위한 Bool 변수
    let isCurrentProject: Bool
    /// 썸네일 이미지입니다.
    let image: Image
    /// 프로젝트의 총길이(sec 단위)를 넘겨주시면 여기서 계산해서 쓰도록 하겠습니다
    let time: Double
    
    /// project edit으로 이동하는 클로저
    let moveToProjectEdit: () -> Void
    
    // MARK: Computed properties
    var formattedTime: String {
        let timeInt = Int(time)
        
        let minutes = timeInt / 60
        let seconds = timeInt % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: body
    var body: some View {
        GeometryReader { geometry in
            if !isCurrentProject {
                ZStack(alignment: .bottomTrailing) {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.width, alignment: .center)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Text(formattedTime)
                        .font(SnappieFont.style(.proLabel2))
                        .foregroundStyle(Color.matcha50)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 0)
                        .foregroundStyle(SnappieColor.labelPrimaryNormal)
                        .padding(12)
                }
                .onTapGesture {
                    moveToProjectEdit()
                }
            }
            else {
                Text("촬영 중인\n프로젝트는\n선택할 수 없음")
                    .font(SnappieFont.style(.proBody1))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.deepGreen200)
                    .frame(width: geometry.size.width, height: geometry.size.width, alignment: .center)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(SnappieColor.darkStrong)
                    )
            }
        }
        .aspectRatio(1, contentMode: .fit) // 정사각형 비율 유지
    }
}

#Preview {
    ProjectCardCoverImageView(
        isCurrentProject: false,
        image: Image("pinggu"),
        time: 150.8,
        moveToProjectEdit: {
            print("moveToProjectEdit")
        }
    )
    .frame(width: 173)
}
