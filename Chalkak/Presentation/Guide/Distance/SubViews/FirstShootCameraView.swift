//
//  FirstShootCameraView.swift
//  Chalkak
//
//  Created by 배현진 on 7/22/25.
//

import SwiftUI

struct FirstShootCameraView: View {
    @StateObject private var viewModel = BoundingBoxViewModel()
    @StateObject private var cameraViewModel = CameraViewModel()

    var body: some View {
        ZStack {
            CameraView(shootState: .firstShoot, isAligned: false, viewModel: cameraViewModel)
        }
        .onAppear() {
            viewModel.deleteUserDefault()
        }
    }
}
