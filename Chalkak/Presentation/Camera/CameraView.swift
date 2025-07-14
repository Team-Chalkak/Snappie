//
//  CameraView.swift
//  Chalkak
//
//  Created by 정종문 on 7/12/25.
//

import SwiftUI

struct CameraView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: CameraViewModel = .init(context: nil)

    var body: some View {
        ZStack {
            CameraPreviewView(session: viewModel.session)
                .onAppear {
                    viewModel.configure()
                }

            VStack {
                // 상단 컨트롤바
                HStack {
                    if viewModel.isRecording {
                        Text(viewModel.formattedTime)
                            .foregroundColor(.black)
                            .font(.system(size: 18, weight: .medium))
                            .padding(.all, 8)
                            .background(.white)
                            .cornerRadius(10)
                    }
                    else {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .center) {
                                CircleIconButton(iconName: viewModel.showingCameraControl ? "chevron.up" : "chevron.down", action: viewModel.switchCameraControls,
                                                 iconSize: (28, 37),
                                                 isSelected: viewModel.showingCameraControl)
                                    .frame(maxWidth: .infinity)

                                ForEach(0 ..< 3) { _ in
                                    Spacer()
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            if viewModel.showingCameraControl {
                                HStack(alignment: .center, spacing: 0) {
                                    CameraBaseFeatureSelectView(viewModel: viewModel)
                                }
                            }
                        }
                    }
                }.padding(.top, 50)

                Spacer()

                // 하단 컨트롤바
                VStack(spacing: 20) {
                    // 녹화 상태 표시
                    CameraRecordView(viewModel: viewModel)
                }
                .foregroundColor(.white)
            }
        }
    }
}
