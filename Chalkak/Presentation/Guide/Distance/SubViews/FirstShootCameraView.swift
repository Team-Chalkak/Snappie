//
//  FirstShootCameraView.swift
//  Chalkak
//
//  Created by 배현진 on 7/22/25.
//

import SwiftUI

struct FirstShootCameraView: View {
    let onboardingVideoSaved: ((URL, CameraSetting, CameraManager, [TimeStampedTilt]) -> Void)?
    let onboardingExit: (() -> Void)?
    
    @State private var viewModel = BoundingBoxViewModel()
    @State private var cameraViewModel = CameraViewModel()
    
    init(
        onboardingVideoSaved: ((URL, CameraSetting, CameraManager, [TimeStampedTilt]) -> Void)? = nil,
        onboardingExit: (() -> Void)? = nil
    ) {
        self.onboardingVideoSaved = onboardingVideoSaved
        self.onboardingExit = onboardingExit
    }
    
    var body: some View {
        ZStack {
            CameraView(
                shootState: .firstShoot,
                isAligned: false,
                viewModel: cameraViewModel,
                onboardingVideoSaved: onboardingVideoSaved,
                onboardingExit: onboardingExit
            )
        }
        .onAppear() {
            viewModel.deleteUserDefault()
        }
    }
}
