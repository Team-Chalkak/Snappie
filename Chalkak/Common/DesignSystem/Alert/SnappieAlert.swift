//
//  SnappieAlert.swift
//  Chalkak
//
//  Created by 정종문 on 7/29/25.
//

import SwiftUI

/// 1초 후 사라지는 토스트 Alert
struct SnappieAlert: View {
    let message: String

    init(message: String) {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 10) {
            Text(message)
                .font(SnappieFont.style(.proLabel1))
                .foregroundColor(SnappieColor.labelPrimaryNormal)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(SnappieColor.labelPrimaryNormal)
                .frame(width: 120, height: 120)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(SnappieColor.darkNormal)
        .cornerRadius(10)
        .padding(.horizontal, 85)
    }
}

struct SnappieAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                SnappieAlert(message: message)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isPresented = false
                            }
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

extension View {
    func snappieAlert(isPresented: Binding<Bool>, message: String) -> some View {
        modifier(SnappieAlertModifier(isPresented: isPresented, message: message))
    }
}

#Preview {
    struct TestView: View {
        @State private var showAlert = false

        var body: some View {
            VStack(spacing: 20) {
                Button("내보내기") {
                    showAlert = true
                }
                .snappieAlert(isPresented: $showAlert, message: "내보내기 완료")
            }
        }
    }
    return TestView()
}
