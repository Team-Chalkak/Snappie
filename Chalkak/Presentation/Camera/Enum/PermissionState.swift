//
//  Permission.swift
//  Chalkak
//
//  Created by Murphy on 8/6/25.
//
enum PermissionState {
    case both           // 모든 권한 허용됨
    case cameraOnly           // 카메라만 권한 허용
    case audioOnly            // 오디오만 권한 허용
    case none                 // 둘 다 권한 없음
}
