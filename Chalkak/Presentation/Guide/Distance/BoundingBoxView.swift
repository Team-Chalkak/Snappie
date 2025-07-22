//
//  BoundingBoxView.swift
//  Chalkak
//
//  Created by 배현진 on 7/14/25.
//

import SwiftUI

struct BoundingBoxView: View {
    let guide: Guide?

    var body: some View {
        if guide == nil {
            FirstShootCameraView()
        } else {
            GuideCameraView(guide: guide)
        }
    }
}
