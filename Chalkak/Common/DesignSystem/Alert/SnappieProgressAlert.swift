//
//  SnappieProgressAlert.swift
//  Chalkak
//
//  Created by 정종문 on 7/29/25.
//

import SwiftUI

/// Progress Alert 조합 View
/// Progress 표시 후 완료 시 Alert로 전환
struct SnappieProgressAlert: View {
    @Binding var isPresented: Bool
    @Binding var isLoading: Bool
    let loadingMessage: String
    let completionMessage: String

    var body: some View {
        ZStack {
            if isPresented && isLoading {
                SnappieProgress(message: loadingMessage)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            } else if isPresented && !isLoading {
                SnappieAlert(message: completionMessage)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    .onAppear {
                        // Alert는 1초 후 자동으로 사라짐
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isPresented = false
                            }
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

struct SnappieProgressAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var isLoading: Bool
    let loadingMessage: String
    let completionMessage: String

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                SnappieProgressAlert(
                    isPresented: $isPresented,
                    isLoading: $isLoading,
                    loadingMessage: loadingMessage,
                    completionMessage: completionMessage
                )
            }
        }
    }
}

extension View {
    /// Progress와 Alert를 조합한 modifier
    /// - Parameters:
    ///   - isPresented: 전체 UI 표시 여부
    ///   - isLoading: 로딩 중 여부 (true: Progress, false: Alert)
    ///   - loadingMessage: 로딩 중 메시지
    ///   - completionMessage: 완료 메시지
    func snappieProgressAlert(
        isPresented: Binding<Bool>,
        isLoading: Binding<Bool>,
        loadingMessage: String,
        completionMessage: String
    ) -> some View {
        modifier(
            SnappieProgressAlertModifier(
                isPresented: isPresented,
                isLoading: isLoading,
                loadingMessage: loadingMessage,
                completionMessage: completionMessage
            )
        )
    }
}

#Preview {
    struct TestView: View {
        @State private var showProgressAlert = false
        @State private var isLoading = false

        var body: some View {
            VStack(spacing: 20) {
                Button("저장하기") {
                    showProgressAlert = true
                    isLoading = true
                }
                .snappieProgressAlert(
                    isPresented: $showProgressAlert,
                    isLoading: $isLoading,
                    loadingMessage: "저장 중...",
                    completionMessage: "저장 완료!"
                )

                Button("HI") {
                    isLoading = false
                }
            }
        }
    }
    return TestView()
}
