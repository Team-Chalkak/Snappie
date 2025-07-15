//
//  HeightMeasurementARView.swift
//  Chalkak
//
//  Created by 석민솔 on 7/14/25.
//

import ARKit
import RealityKit
import SwiftUI

/**
 ARView를 SwiftUI에서 사용하기 위한 래퍼 컨테이너
 
 이 구조체는 ARKit의 ARView를 SwiftUI 뷰 계층에 통합하여 실시간 높이 측정 기능을 제공합니다.
 바닥 평면을 감지하고 디바이스의 높이를 지속적으로 계산합니다.
 
 ## 사용법
 ```swift
 @State private var measuredHeight: Float = 0.0
 @State private var isGroundFound: Bool = false
 
 HeightMeasurementARView(measuredHeight: $measuredHeight, isGroundFound: $isGroundFound)
 ```
 
 ## 기능
 - 수평 평면 감지 (바닥 감지)
 - 실시간 높이 측정
 - 바닥 발견 상태 추적
 */
struct HeightMeasurementARView: UIViewRepresentable {
    // MARK: - Properties
    /// 측정된 디바이스의 높이 (미터 단위)
    @Binding var measuredHeight: Float

    /// 바닥이 발견되었는지 여부를 나타내는 상태
    @Binding var isGroundFound: Bool

    // MARK: - Methods
    /// UIKit의 ARView를 생성하고 ARKit 세션을 설정합니다.
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // ARKit 설정
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]  // 수평 평면인 바닥 감지
        configuration.environmentTexturing = .automatic

        arView.session.run(configuration)

        // delegate 연결
        arView.session.delegate = context.coordinator

        return arView
    }

    /// ARView를 업데이트하고 Coordinator와 parent의 연결을 설정합니다.
    func updateUIView(_ uiView: ARView, context: Context) {
        // Coordinator가 SwiftUI에 접근할 수 있도록 연결
        context.coordinator.parent = self
    }

    /// ARSession 이벤트를 처리하는 Coordinator를 생성합니다.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator
    /// ARSession의 이벤트를 처리하고 높이 측정 로직을 관리하는 클래스
    ///
    /// 이 클래스는 ARKit의 평면 감지 이벤트를 수신하고, 바닥 평면을 식별하여
    /// 디바이스의 높이를 실시간으로 계산합니다.
    class Coordinator: NSObject, ARSessionDelegate {
        /// 부모 ARViewContainer에 대한 참조
        var parent: HeightMeasurementARView

        /// 감지된 바닥의 Y 좌표 (미터 단위)
        var groundHeight: Float?

        /// 감지된 모든 수평 평면들의 배열
        var detectedPlanes: [ARPlaneAnchor] = []

        /// Coordinator를 초기화합니다.
        init(_ parent: HeightMeasurementARView) {
            self.parent = parent
        }

        /// ARKit이 새로운 평면 앵커를 발견했을 때 호출됩니다.
        ///
        /// 수평 평면을 감지하면 바닥으로 간주하고 높이 계산을 시작합니다.
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {

            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor,
                    planeAnchor.alignment == .horizontal
                {

                    detectedPlanes.append(planeAnchor)
                    updateGroundHeight()

                    // SwiftUI에 바닥 발견 알림
                    DispatchQueue.main.async {
                        self.parent.isGroundFound = true
                    }

                }
            }
        }

        /// 기존 평면 앵커의 정보가 업데이트될 때 호출됩니다.
        ///
        /// 평면의 크기나 위치가 더 정확해지면 바닥 높이를 재계산합니다.
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            var updated = false

            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor,
                    planeAnchor.alignment == .horizontal
                {

                    // 기존 평면 정보 업데이트
                    if let index = detectedPlanes.firstIndex(where: {
                        $0.identifier == planeAnchor.identifier
                    }) {
                        detectedPlanes[index] = planeAnchor
                        updated = true
                    }
                }
            }

            if updated {
                updateGroundHeight()
            }
        }

        /// 매 프레임마다 호출되어 실시간으로 높이를 계산합니다.
        ///
        /// 카메라의 현재 위치와 바닥의 Y 좌표를 사용하여 디바이스의 높이를 계산하고
        /// SwiftUI 바인딩을 통해 UI를 업데이트합니다.
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard let groundY = groundHeight else { return }

            // 현재 카메라 높이
            let cameraY = frame.camera.transform.columns.3.y

            // 높이 계산: 카메라 위치 - 바닥 위치
            let deviceHeight = cameraY - groundY

            // SwiftUI에 실시간 높이 업데이트
            DispatchQueue.main.async {
                self.parent.measuredHeight = deviceHeight
            }
        }

        /// ARSession에서 오류가 발생했을 때 호출됩니다.
        func session(_ session: ARSession, didFailWithError error: Error) {
            print("❌ ARSession 에러: \(error.localizedDescription)")
        }

        /// ARSession이 중단되었을 때 호출됩니다.
        func sessionWasInterrupted(_ session: ARSession) {
            print("⏸️ ARSession 중단됨")
        }

        /// ARSession이 중단 후 재개되었을 때 호출됩니다.
        func sessionInterruptionEnded(_ session: ARSession) {
            print("▶️ ARSession 재개됨")
        }

        /// 감지된 평면들 중 가장 큰 평면을 바닥으로 간주하여 바닥 높이를 업데이트합니다.
        private func updateGroundHeight() {
            guard !detectedPlanes.isEmpty else { return }

            // 가장 큰 평면 찾기
            let largestPlane = detectedPlanes.max { plane1, plane2 in
                let area1 = plane1.planeExtent.width * plane1.planeExtent.height
                let area2 = plane2.planeExtent.width * plane2.planeExtent.height
                return area1 < area2
            }

            if let plane = largestPlane {
                groundHeight = plane.transform.columns.3.y
            }
        }
    }
}
