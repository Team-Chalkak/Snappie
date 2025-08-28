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

    /// 스택에서 특정 Path까지 pop하고 그 이후 화면은 제거
    func popToScreen(_ target: Path) {
        // 마지막 화면부터 탐색
        while let last = path.last {
            if last == target {
                break
            }
            _ = self.path.popLast()
        }
    }
}
