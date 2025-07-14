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
            CameraPreviewView(session: viewModel.session, showGrid: $viewModel.isGrid)

            VStack {
                // 상단 컨트롤바 (기본 촬영 기능들)
                HStack {
                    if viewModel.isTimerRunning {
                        // 타이머 카운트다운 표시
                        Text("\(viewModel.timerCountdown)")
                            .foregroundColor(.white)
                            .font(.system(size: 48, weight: .bold))
                            .frame(width: 80, height: 80)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                            .scaleEffect(viewModel.timerCountdown > 0 ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.5), value: viewModel.timerCountdown)
                    } else if viewModel.isRecording {
                        Text(viewModel.formattedTime)
                            .foregroundColor(.black)
                            .font(.system(size: 18, weight: .medium))
                            .padding(.all, 8)
                            .background(.white)
                            .cornerRadius(10)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .center) {
                                CircleIconButton(iconName: viewModel.showingCameraControl ? "chevron.up" : "chevron.down", action: viewModel.switchCameraControls,
                                                 iconSize: (28, 37),
                                                 isSelected: viewModel.showingCameraControl)
                                    .frame(maxWidth: .infinity)
                                    .disabled(viewModel.isTimerRunning) // 타이머 중 비활성화
                                ForEach(0 ..< 3) { _ in
                                    Spacer()
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            if viewModel.showingCameraControl && !viewModel.isTimerRunning {
                                HStack(alignment: .center, spacing: 0) {
                                    if viewModel.showingTimerControl {
                                        TimerOptionSelectView(viewModel: viewModel)
                                    } else {
                                        CameraBaseFeatureSelectView(viewModel: viewModel)
                                    }
                                }
                            }
                        }
                        .opacity(viewModel.isTimerRunning ? 0.5 : 1.0)
                    }
                }.padding(.top, 50)

                Spacer()

                // 하단 컨트롤바 (줌인/아웃,촬영,전환)
                VStack(spacing: 20) {
                    HStack {
                        if viewModel.showingZoomControl && !viewModel.isTimerRunning {
                            HStack(spacing: 15) {
                                ZoomSlider(
                                    zoomScale: viewModel.zoomScale,
                                    minZoom: viewModel.minZoomScale,
                                    maxZoom: viewModel.maxZoomScale,
                                    onValueChanged: { newValue in
                                        viewModel.selectZoomScale(newValue)
                                    }
                                )
                                .frame(maxWidth: .infinity)

                                Button(action: {
                                    viewModel.toggleZoomControl()
                                }) {
                                    VStack(spacing: 2) {
                                        Text(String(format: "%.1fx", viewModel.zoomScale))
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 55, height: 55)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                                }
                            }
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        } else {
                            Spacer()

                            Button(action: {
                                if !viewModel.isTimerRunning {
                                    viewModel.toggleZoomControl()
                                }
                            }) {
                                VStack(spacing: 2) {
                                    Text(String(format: "%.1fx", viewModel.zoomScale))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .frame(width: 55, height: 55)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                                .opacity(viewModel.isTimerRunning ? 0.5 : 1.0)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.showingZoomControl)

                    CameraRecordView(viewModel: viewModel)
                }
                .foregroundColor(.white)
                .foregroundColor(.white)
            }
        }
    }
}
