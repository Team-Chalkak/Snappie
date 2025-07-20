//
//  VideoLoader.swift
//  Chalkak
//
//  Created by 석민솔 on 7/16/25.
//

import Foundation

import Foundation

 /**
 내부 저장소에 저장되어있는 현재 프로젝트의 비디오 정보를 불러오는 구조체

 `VideoLoader`는 UserDefaults와 SwiftData를 활용하여 현재 작업 중인 프로젝트의 클립 데이터를 로드합니다.

 ## 사용 예시
 ```swift
 let videoLoader = VideoLoader()

 Task {
     let clips = await videoLoader.loadProjectClipList()
     print("로드된 클립 수: \(clips.count)")
 }
 ```
 */
struct VideoLoader {
    
    /// UserDefaults와 SwiftData 내부 저장소에서 현재 작업중인 프로젝트의 클립 데이터를 받아옵니다.
    ///
    /// UserDefaults에서 현재 프로젝트 ID를 가져오고, SwiftData에서 해당 프로젝트의 클립 리스트를 로드합니다.
    ///
    /// - Returns: 현재 프로젝트의 클립 배열. 프로젝트가 없으면 빈 배열
    func loadProjectClipList() async -> [Clip] {
        guard let projectID = UserDefaults().string(forKey: "currentProjectID"),
           let project = await SwiftDataManager.shared.fetchProject(byID: projectID) else {
            return []
        }
        
        return project.clipList
    }
}
