//
//  FileManager+Extensions.swift
//  Chalkak
//
//  Created by Claude on 7/30/25.
//

import Foundation

extension FileManager {
    /// 앱의 Documents 디렉토리 URL을 반환합니다.
    static var documentsDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// 비디오 파일의 현재 유효한 URL을 반환합니다.
    /// 앱 재시작으로 인해 Documents 디렉토리 경로가 변경된 경우 새로운 경로로 업데이트합니다.
    static func validVideoURL(from originalURL: URL) -> URL? {
        // 파일이 여전히 존재하는지 확인
        if FileManager.default.fileExists(atPath: originalURL.path) {
            return originalURL
        }
        
        // 파일명만 추출하여 현재 Documents 디렉토리에서 찾기
        let fileName = originalURL.lastPathComponent
        let newURL = documentsDirectory.appendingPathComponent(fileName)
        
        // 새로운 경로에서 파일 존재 확인
        if FileManager.default.fileExists(atPath: newURL.path) {
            return newURL
        }
        
        return nil
    }
    
    /// URL이 유효한 비디오 파일을 가리키는지 확인합니다.
    static func isValidVideoFile(at url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path) && 
               url.pathExtension.lowercased() == "mp4"
    }
}