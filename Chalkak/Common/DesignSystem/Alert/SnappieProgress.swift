//
//  SnappieProgress.swift
//  Chalkak
//
//  Created by 정종문 on 7/29/25.
//

import SwiftUI

/// 프로그레스 표시 Alert (내보내는 중 등에 사용)
struct SnappieProgress: View {
    let message: String
    @State private var rotationAngle: Double = 0
    
    private var progressGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(stops: [
                .init(color: Color("matcha-50").opacity(0), location: 0.07),
                .init(color: Color("matcha-50").opacity(1.0), location: 0.84),
            ]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360)
        )
    }
    
    init(message: String) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text(message)
                .font(SnappieFont.style(.proLabel1))
                .foregroundColor(SnappieColor.labelPrimaryNormal)
            
            ZStack {
                Circle()
                    .stroke(SnappieColor.darkLight, lineWidth: 6)
                    .frame(width: 106, height: 106)
                
                // Angular gradient progress
                Circle()
                    .trim(from: 0, to: 0.84)
                    .stroke(progressGradient, style: StrokeStyle(lineWidth: 6, lineCap: .butt))
                    .frame(width: 106, height: 106)
                    .rotationEffect(.degrees(rotationAngle))
                    .onAppear {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            rotationAngle = 360
                        }
                    }
            }
            .frame(width: 120, height: 120)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(SnappieColor.darkNormal)
        .cornerRadius(10)
        .padding(.horizontal, 85)
    }
}

struct SnappieProgressModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                SnappieProgress(message: message)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

extension View {
    func snappieProgress(isPresented: Binding<Bool>, message: String) -> some View {
        modifier(SnappieProgressModifier(isPresented: isPresented, message: message))
    }
}

#Preview {
    struct TestView: View {
        @State private var showProgress = false
    
        var body: some View {
            VStack(spacing: 20) {
                Button("저장 중") {
                    showProgress = true
                }
                .snappieProgress(isPresented: $showProgress, message: "저장 중...")
            }
        }
    }
    return TestView()
}
