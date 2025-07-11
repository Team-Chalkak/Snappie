//
//  CameraViewModel.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

import Foundation
import SwiftData

final class CameraViewModel: ObservableObject {
    private var modelContext: ModelContext?

    init(context: ModelContext?) {
        self.modelContext = context
    }
    
    func updateContext(_ context: ModelContext) {
        self.modelContext = context
    }
}
