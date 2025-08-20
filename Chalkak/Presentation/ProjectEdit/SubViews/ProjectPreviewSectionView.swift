//
//  ProjectPreviewSectionView.swift
//  Chalkak
//
//  Created by 배현진 on 8/21/25.
//

import SwiftUI

struct ProjectPreviewSectionView: View {
    @ObservedObject var viewModel: ProjectEditViewModel
    
    var body: some View {
        ZStack {
            VideoPreviewView(
                previewImage: viewModel.previewImage,
                player: viewModel.player,
                isDragging: viewModel.isDragging
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .snappieProgress(isPresented: $viewModel.isLoading, message: "영상 불러오는 중")
            
            // 선택된 클립이 있을 때만 Delete 버튼 표시
            if let trimmingClip = viewModel.editableClips.first(where: { $0.isTrimming }) {
                VStack {
                    Spacer()
                    Button(action: {
                        viewModel.deleteClip(id: trimmingClip.id)
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(SnappieColor.redRecording)
                            .padding(8)
                            .frame(width: 40, height: 40, alignment: .center)
                            .background(SnappieColor.containerFillNormal)
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }
}
