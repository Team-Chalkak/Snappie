//
//  ProjectPreviewViewModel.swift
//  Chalkak
//
//  Created by 석민솔 on 7/17/25.
//

import AVFoundation
import Foundation
import SwiftData

/// ProjectPreviewView의 뷰모델
final class ProjectPreviewViewModel: ObservableObject {
    // MARK: - Properties
    let finalVideoURL: URL
    let player: AVPlayer
    let photoLibrarySaver: PhotoLibrarySaver = .init()
    @Published var isExportFinished: Bool = false
    
    // MARK: - init
    init(finalVideoURL: URL) {
        self.finalVideoURL = finalVideoURL
        self.player = AVPlayer(url: finalVideoURL)
        player.play()
    }
    
    // MARK: - Methods
    /// 비디오를 사진 라이브러리에 저장
    func exportToPhotos() async {
        await photoLibrarySaver.saveVideoToLibrary(videoURL: self.finalVideoURL)
        
        DispatchQueue.main.sync {
            self.isExportFinished = true
        }
    }
    
    /// 합본 영상을 임시 저장소에서 제거
    func cleanupTemporaryVideoFile() async {
        do {
            try FileManager.default.removeItem(at: finalVideoURL)
        } catch {
            print("영상 임시 저장소에서 제거 실패: \(error.localizedDescription)")
        }
    }
}
