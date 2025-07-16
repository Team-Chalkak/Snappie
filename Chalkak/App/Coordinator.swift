//
//  Coordinator.swift
//  Chalkak
//
//  Created by 배현진 on 7/16/25.
//

import Foundation

final class Coordinator: ObservableObject {
    @Published var path: [Path] = []

    func push(_ path: Path) {
        self.path.append(path)
    }

    func popLast() {
        _ = self.path.popLast()
    }

    func removeAll() {
        self.path.removeAll()
    }
}
