//
//  Permission.swift
//  Chalkak
//
//  Created by Murphy on 8/6/25.
//
enum PermissionState {
    case allGranted           // 모든 권한 허용됨
    case cameraOnly           // 카메라 권한만 없음
    case audioOnly            // 오디오 권한만 없음
    case both                 // 둘 다 권한 없음
}
