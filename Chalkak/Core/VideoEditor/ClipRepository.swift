//
//  ClipRepository.swift
//  Chalkak
//
//  Created by bishoe01 on 1/9/26.
//

@MainActor
final class ClipRepository {
    private let swiftDataManager = SwiftDataManager.shared

    /// Clip 저장
    func save(_ clip: Clip) throws {
        try swiftDataManager.createClip(clip: clip)
    }

    /// 기존 Project에 Clip 추가
    func appendToProject(clip: Clip, projectID: String) throws {
        guard let project = swiftDataManager.fetchProject(byID: projectID) else {
            throw ClipRepositoryError.projectNotFound
        }
        project.clipList.append(clip)
        swiftDataManager.saveContext()
    }

    /// Clip 트리밍 포인트 수정
    func updatePoints(id: String, start: Double, end: Double) {
        swiftDataManager.updateClipPoints(id: id, start: start, end: end)
    }
}

enum ClipRepositoryError: Error {
    case projectNotFound
}
