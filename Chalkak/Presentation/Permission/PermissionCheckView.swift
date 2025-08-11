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
            ZStack{
                SnappieColor.darkHeavy.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 40){
                    
                    VStack(alignment: .center, spacing: 24){
                        Text("카메라와 마이크 접근 권한 필요")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.matcha50)
                        Text("앱 설정에서 카메라와 마이크의\n접근 설정을 허용해 주세요.")
                            .foregroundStyle(SnappieColor.labelPrimaryNormal)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(alignment: .leading, spacing: 24) {
                        HStack(spacing: 8){
                            
                            permissionIconCamera
                            
                            VStack (alignment: .leading, spacing: 6){
                                Text("카메라 접근 권한")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.matcha50)
                                Text("영상을 녹화하기 위해 접근 권한이 필요해요.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.matcha50)
                            }
                        }
                        
                        HStack(spacing: 8){
                            
                            permissionIconAudio
                            
                            VStack (alignment: .leading, spacing: 6){
                                Text("마이크 접근 권한")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.matcha50)
                                Text("소리를 녹음하기 위해 접근 권한이 필요해요.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.matcha50)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack (alignment: .center){
                        SnappieButton(.solidPrimary(
                            title: "설정 열기",
                            size: .large
                        )) {
                            cameraManager.openSettings()
                            dismiss()
                        }
                        .disabled(false)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 48)
            }
            
        }
        .presentationBackground(.regularMaterial)
        .presentationCornerRadius(20)
        
    }
    
    //권한에 따른 카메라 아이콘
    @ViewBuilder
    private var permissionIconCamera: some View {
        switch cameraManager.permissionState {
        case .both:
            Image("cameraAuthorized")

        case .cameraOnly:
            Image("cameraAuthorized")
            
        case .audioOnly:
            Image("cameraDenied")
            
        case .none:
            Image("cameraDenied")
        }
    }
    
    //권한에 따른 마이크 아이콘
    @ViewBuilder
    private var permissionIconAudio: some View {
        switch cameraManager.permissionState {
        case .both:
            Image("micAuthorized")
            
        case .cameraOnly:
            Image("micDenied")
            
        case .audioOnly:
            Image("micAuthorized")
            
        case .none:
            Image("micDenied")
        }
    }
}

                    


#Preview {
    CameraPermissionSheet(cameraManager: CameraManager())
}
