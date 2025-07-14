//
//  CameraView.swift
//  Chalkak
//
//  Created by 정종문 on 7/12/25.
//

import SwiftUI

struct CameraView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = CameraViewModel(context: nil)

    var body: some View {
        ZStack {
            viewModel.cameraPreview
                .onAppear {
                    viewModel.configure()
                }

            VStack {
                // 상단 컨트롤
                HStack {
                    Spacer()

                    // 카메라 전환 버튼
                    Button(action: { viewModel.changeCamera() }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)

                Spacer()

                // 하단 컨트롤
                VStack(spacing: 20) {
                    // 녹화 상태 표시
                    if viewModel.isRecording {
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                            Text("녹화 중...")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                    }

                    ZStack {
                        // 메인 셔터/녹화 버튼
                        Button(action: {
                            if viewModel.isRecording {
                                viewModel.stopVideoRecording()
                            } else {
                                viewModel.startVideoRecording()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(lineWidth: 5)
                                    .frame(width: 75, height: 75)
                                    .foregroundColor(.white)

                                Circle()
                                    .fill(viewModel.isRecording ? Color.red : Color.white)
                                    .frame(width: 60, height: 60)

                                if viewModel.isRecording {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white)
                                        .frame(width: 20, height: 20)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 50)
            }
            .foregroundColor(.white)
        }
    }
}
