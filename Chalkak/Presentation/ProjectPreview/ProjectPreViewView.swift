//
//  ProjectPreViewView.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

import SwiftUI

struct ProjectPreViewView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject var viewModel: CameraViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: CameraViewModel(context: nil))
    }
    
    var body: some View {
        VStack {
            Text("ProjectPreViewView")
        }
        .padding()
        .onAppear {
            viewModel.updateContext(modelContext)
        }
    }
}

#Preview {
    ProjectPreViewView()
}
