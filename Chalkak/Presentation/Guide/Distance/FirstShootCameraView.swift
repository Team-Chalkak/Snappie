//
//  FirstShootCameraView.swift
//  Chalkak
//
//  Created by 배현진 on 7/22/25.
//

import SwiftUI

struct FirstShootCameraView: View {
    @StateObject private var cameraViewModel = CameraViewModel()

    var body: some View {
        ZStack {
            CameraView(isFirstShoot: true, guide: nil, viewModel: cameraViewModel)
        }
    }
}
