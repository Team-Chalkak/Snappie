//
//  ProjectPreviewView.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

import SwiftUI

struct ProjectPreviewView: View {
    @StateObject var viewModel: CameraViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: CameraViewModel())
    }
    
    var body: some View {
        VStack {
            Text("ProjectPreViewView")
        }
        .padding()
    }
}

#Preview {
    ProjectPreviewView()
}
