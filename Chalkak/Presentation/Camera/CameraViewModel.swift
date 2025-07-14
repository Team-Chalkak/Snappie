//
//  CameraViewModel.swift
//  Chalkak
//
//  Created by 정종문 on 7/12/25.
//

import AVFoundation
import Foundation
import Photos
import SwiftData
import SwiftUI

class CameraViewModel: ObservableObject {
    private var modelContext: ModelContext?
    private let model: CameraManager
    private let session: AVCaptureSession
    let cameraPreview: AnyView
    
    @Published var isFlashOn = false
    @Published var isSilentModeOn = false
    @Published var cameraPostion: AVCaptureDevice.Position = .back
    @Published var isRecording = false
    
    func configure() {
        model.requestAndCheckPermissions()
    }
    
    func switchFlash() {
        isFlashOn.toggle()
    }
    
    func switchSilent() {
        isSilentModeOn.toggle()
    }

    func startVideoRecording() {
        model.startRecording()
        isRecording = true
    }
    
    func stopVideoRecording() {
        model.stopRecording()
        isRecording = false
    }
    
    func changeCamera() {
        cameraPostion = cameraPostion == .back ? .front : .back
        model.switchCamera(to: cameraPostion)
    }
    
    init(context: ModelContext?) {
        model = CameraManager()
        session = model.session
        cameraPreview = AnyView(CameraPreviewView(session: session))
        modelContext = context
        
        model.$isRecording
            .assign(to: &$isRecording)
    }

    func updateContext(_ context: ModelContext) {
        modelContext = context
    }
}
