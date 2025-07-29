//
//  ZoomButtonGestureModifier.swift
//  Chalkak
//
//  Created by 정종문 on 7/28/25.
//

import SwiftUI

/// 줌 버튼의 탭과 롱프레스 제스처를 처리 
/// 탭은 줌 인디케이터로 기본값이동 
/// 롱프레스는 줌 슬라이더 소환 
struct ZoomButtonGestureModifier: ViewModifier {
    let onTap: () -> Void
    let onLongPress: () -> Void

    /// 뷰에 탭과 롱프레스 제스처를 적용
    func body(content: Content) -> some View {
        content
            .onTapGesture(perform: onTap)
            .onLongPressGesture(minimumDuration: 0.5, perform: onLongPress)
    }
}

/// 사용예시
// struct ContentView: View {
//     var body: some View {
//         Text("Hello, World!")
//             .zoomButtonGestures(onTap: {
//                 print("Tap")
//             }, onLongPress: {
//                 print("Long Press")
//             })
//     }
// }
extension View {
    func zoomButtonGestures(
        onTap: @escaping () -> Void,
        onLongPress: @escaping () -> Void
    ) -> some View {
        modifier(ZoomButtonGestureModifier(onTap: onTap, onLongPress: onLongPress))
    }
}
