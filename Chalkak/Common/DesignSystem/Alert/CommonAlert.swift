//
//  CommonAlert.swift
//  Chalkak
//
//  Created by finn on 7/29/25.
//

import SwiftUI

/// 공통 Alert 타입 정의
enum AlertType {
    case deleteProject
    case retakeVideo
    case finishShooting
    case retakeCurrentVideo
    case endShooting
    case exitWhileRecording
    case resumeProject

    var title: String {
        switch self {
        case .deleteProject: return "프로젝트를 삭제하시겠습니까?"
        case .retakeVideo: return "다시 촬영할까요?"
        case .finishShooting: return "촬영을 마치고 나갈까요?"
        case .retakeCurrentVideo: return "다시 촬영할까요?"
        case .endShooting: return "촬영 종료하기"
        case .exitWhileRecording: return "다시 찍으시겠어요?"
        case .resumeProject: return "촬영 중인 프로젝트가 있어요."
        }
    }

    var message: String {
        switch self {
        case .deleteProject: return "프로젝트와 클립이 모두 삭제됩니다."
        case .retakeVideo: return "방금 찍은 영상은 저장되지 않아요."
        case .finishShooting: return "지금까지 찍은 장면은 저장돼요."
        case .retakeCurrentVideo: return "방금 찍은 영상은 저장되지 않아요."
        case .endShooting: return "지금까지 촬영된 클립을 저장하고 카메라로 돌아가시겠어요?"
        case .exitWhileRecording: return "지금 나가면 방금 찍은 영상이 지워져요."
        case .resumeProject: return "다음 장면을 이어서 촬영할까요?"
        }
    }

    var confirmText: String {
        switch self {
        case .deleteProject: return "삭제"
        case .retakeVideo: return "나가기"
        case .finishShooting: return "나가기"
        case .retakeCurrentVideo: return "확인"
        case .endShooting: return "종료"
        case .exitWhileRecording: return "확인"
        case .resumeProject: return "이어서 촬영"
        }
    }
}

/*
 사용 예시
 @State private var showAlert = false

 // 취소 액션 생략 dismiss 효과
 .alert(.deleteProject, isPresented: $showAlert) {
     deleteProject()
 }

 // 취소 액션 처리
 .alert(.deleteProject, isPresented: $showAlert,
        cancelAction: { print("취소됨") },
        confirmAction: { deleteProject() })
 */

extension View {
    func alert(
        _ type: AlertType,
        isPresented: Binding<Bool>,
        cancelAction: @escaping () -> Void = {},
        confirmAction: @escaping () -> Void
    ) -> some View {
        self.alert(isPresented: isPresented) {
            Alert(
                title: Text(type.title),
                message: Text(type.message),
                primaryButton: .cancel(Text("취소"), action: cancelAction),
                secondaryButton: .default(Text(type.confirmText), action: confirmAction)
            )
        }
    }
}
