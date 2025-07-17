//
//  ProjectPreviewViewModel.swift
//  Chalkak
//
//  Created by 석민솔 on 7/17/25.
//

import AVFoundation
import Foundation
import SwiftData

final class ProjectPreviewViewModel: ObservableObject {
    // MARK: - Properties
    let finalVideoURL: URL
    let player: AVPlayer
    
    // MARK: - init
    init(finalVideoURL: URL) {
        self.finalVideoURL = finalVideoURL
        self.player = AVPlayer(url: finalVideoURL)
    }
    
    // MARK: - Methods
        
    /// 합본 영상을 임시 저장소에서 제거
    func cleanupTemporaryVideoFile() async {
        do {
            try FileManager.default.removeItem(at: finalVideoURL)
        } catch {
            print("영상 임시 저장소에서 제거 실패: \(error.localizedDescription)")
        }
    }
}
