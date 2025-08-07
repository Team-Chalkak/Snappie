//
//  Untitled.swift
//  Chalkak
//
//  Created by Murphy on 8/6/25.
//
import SwiftUI
import AVFoundation

struct CameraPermissionSheet: View {
    @ObservedObject var cameraManager: CameraManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32){
                
                VStack(alignment: .center, spacing: 24){
                    Text("카메라와 마이크 접근 권한 필요")
                        .font(.title)
                    Text("앱 설정에서 카메라와 마이크의\n접근 설정을 허용해 주세요.")
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 20) {
                    HStack(spacing: 20){
                        
                        permissionIconCamera
                        
                        VStack (alignment: .leading, spacing: 16){
                            Text("카메라 접근 권한")
                                .font(.title2)
                            Text("영상을 녹화하기 위해 접근 권한이 필요해요.")
                        }
                    }
                    
                    HStack(spacing: 20){
                        
                        permissionIconAudio
                        
                        VStack (alignment: .leading, spacing: 16){
                            Text("마이크 접근 권한")
                                .font(.title2)
                            Text("소리를 녹음하기 위해 접근 권한이 필요해요.")
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    cameraManager.openSettings()
                    dismiss()
                } label: {
                    Text("설정 열기")
                }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            
        }
        
    }
    
    //권한에 따른 카메라 아이콘
    @ViewBuilder
    private var permissionIconCamera: some View {
        switch cameraManager.permissionState {
        case .allGranted:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
        case .cameraOnly:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
        case .audioOnly:
            Image(systemName: "camera.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
        case .both:
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
        }
    }
    
    //권한에 따른 마이크 아이콘
    @ViewBuilder
    private var permissionIconAudio: some View {
        switch cameraManager.permissionState {
        case .allGranted:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
        case .cameraOnly:
            Image(systemName: "microphone.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
        case .audioOnly:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
        case .both:
            Image(systemName: "microphone.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
        }
    }
}

                    


//#Preview {
//    CameraPermissionSheet()
//}
