//
//  CameraBottomControlView.swift
//  Chalkak
//
//  Created by 정종문 on 7/15/25.
//

import SwiftUI

struct CameraBottomControlView: View {
    @ObservedObject var viewModel: CameraViewModel

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                if viewModel.showingZoomControl && !viewModel.isTimerRunning && !viewModel.isUsingFrontCamera {
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
                    if !viewModel.isUsingFrontCamera {
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
            }
            .padding(.horizontal, 20)
            .animation(.easeInOut(duration: 0.3), value: viewModel.showingZoomControl)

            CameraRecordView(viewModel: viewModel)
        }
        .foregroundColor(.white)
    }
}
