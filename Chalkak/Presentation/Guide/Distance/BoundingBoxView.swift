//
//  BoundingBoxView.swift
//  Chalkak
//
//  Created by 배현진 on 7/14/25.
//

import SwiftUI

struct BoundingBoxView: View {
    let shootState: ShootState

    @State private var viewModel = BoundingBoxViewModel()
    @EnvironmentObject private var coordinator: Coordinator
    @Environment(PermissionManager.self) private var permissionManager

    var body: some View {
        Group {
            switch shootState {
            case .firstShoot:
                FirstShootCameraView()
            case .followUpShoot(let guide),
                 .appendShoot(let guide):
                GuideCameraView(guide: guide, shootState: shootState)
            }
        }
        .onAppear {
            permissionManager.reevaluateAndPresentIfNeeded()
        }
    }
}
