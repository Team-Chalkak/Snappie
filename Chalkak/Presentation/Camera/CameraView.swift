//
//  CameraView.swift
//  Chalkak
//
//  Created by 정종문 on 7/12/25.
//

import SwiftUI

struct CameraView: View {
    let shootState: ShootState
    let isAligned: Bool
    
    private var guide: Guide? {
        switch shootState {
        case .firstShoot:
            return nil
        case .followUpShoot(let guide), .appendShoot(let guide):
            return guide
        }
    }
    
    @StateObject private var cameraManager = CameraManager()
    @ObservedObject var viewModel: CameraViewModel
    @EnvironmentObject private var coordinator: Coordinator

    @State private var clipUrl: URL?
    @State private var navigateToEdit = false
    @State private var feedbackOpacity: Double = 0
    @State private var fadeOutTask: Task<Void, Never>?
    @State private var showExitAlert = false

    var body: some View {
        ZStack {
            if isAligned {
                SnappieColor.primaryStrong.edgesIgnoringSafeArea(.all)
            } else {
                SnappieColor.darkHeavy.edgesIgnoringSafeArea(.all)
            }
            
            ZStack {
                CameraPreviewView(
                    session: viewModel.session,
                    tabToFocus: viewModel.focusAtPoint,
                    onPinchZoom: viewModel.selectZoomScale,
                    currentZoomScale: viewModel.zoomScale,
                    isUsingFrontCamera: viewModel.isUsingFrontCamera,
                    showGrid: $viewModel.isGrid
                )
                .aspectRatio(9 / 16, contentMode: .fit)
                .clipped()
                
                // 타이머 설정 오버레이
                if viewModel.showTimerFeedback != nil {
                    Text("\(viewModel.showTimerFeedback!.rawValue)")
                        .font(SnappieFont.style(.kronaExtra))
                        .foregroundColor(SnappieColor.labelPrimaryNormal)
                        .opacity(feedbackOpacity)
                }
                
                // 타이머 카운트다운 오버레이
                if viewModel.isTimerRunning && viewModel.timerCountdown > 0 {
                    Text("\(viewModel.timerCountdown)")
                        .font(SnappieFont.style(.kronaExtra))
                        .foregroundColor(SnappieColor.labelPrimaryNormal)
                        .transition(.opacity)
                        .animation(.easeOut(duration: 0.4), value: viewModel.timerCountdown)
                }
            }
            .padding(.top, Layout.preViewTopPadding)
            .padding(.horizontal, Layout.preViewHorizontalPadding)
            .frame(maxHeight: .infinity, alignment: .top)
            
            // 수평 레벨 표시
            if viewModel.isHorizontalLevelActive {
                HorizontalLevelIndicatorView(gravityX: viewModel.tiltCollector.gravityX)
            }
            
            // 두번째 촬영부터-중간이탈버튼
            if guide != nil {
                VStack {
                    HStack {
                        SnappieButton(.iconBackground(
                            icon: .dismiss,
                            size: .large,
                            isActive: true
                        )) {
                            showExitAlert = true
                        }
                        .padding(.leading, 30)
                        .padding(.top, 25)
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
            }
            
            VStack {
                CameraTopControlView(viewModel: viewModel, guide: guide)
                
                Spacer()
                
                CameraBottomControlView(viewModel: viewModel)
            }.padding(.horizontal, Layout.cameraControlHorizontalPadding)
        }
        .onChange(of: viewModel.showTimerFeedback) { _, newValue in
            fadeOutTask?.cancel()
            
            if newValue != nil {
                // 즉시 opacity 1
                feedbackOpacity = 1
                fadeOutTask = Task {
                    do {
                        // 대기 1초
                        try await Task.sleep(nanoseconds: 700_000_000)
                        
                        // 태스크가 취소되지 않았다면 페이드아웃
                        if !Task.isCancelled {
                            withAnimation(.easeOut(duration: 0.3)) {
                                // nil 로 하면 fadeout이 적용되지않아서 opacity로 조절
                                feedbackOpacity = 0
                            }
                        }
                    } catch {
                        print("Error: \(error)")
                    }
                }
            }
        }
        .onReceive(viewModel.videoSavedPublisher) { url in
            self.clipUrl = url
            let cameraSetting = viewModel.saveCameraSettingToUserDefaults()
            
            coordinator.push(.clipEdit(
                clipURL: url,
                guide: guide,
                cameraSetting: cameraSetting,
                TimeStampedTiltList: viewModel.timeStampedTiltList
            )
            )
        }
        .onAppear {
            viewModel.startCamera()
            cameraManager.checkPermissions()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
        .alert("촬영을 마치고 나갈까요?", isPresented: $showExitAlert) {
            Button("취소", role: .cancel) {}
            Button("나가기", role: .destructive) {
                handleExitCamera()
            }
        } message: {
            Text("지금까지 찍은 장면은 저장돼요.")
        }
        .snappieAlert(isPresented: $viewModel.showProjectSavedAlert, message: "프로젝트가 저장되었습니다")
        
        .sheet(isPresented: $cameraManager.showPermissionSheet) {
            CameraPermissionSheet(cameraManager: cameraManager)
        }
    }
    

    private func handleExitCamera() {
        UserDefaults.standard.set(nil, forKey: "currentProjectID")

        viewModel.stopCamera()
        coordinator.removeAll()
    }
}

private extension CameraView {
    enum Layout {
        static let preViewTopPadding: CGFloat = 12
        static let preViewHorizontalPadding: CGFloat = 16
        static let cameraControlHorizontalPadding: CGFloat = 8
    }
}
