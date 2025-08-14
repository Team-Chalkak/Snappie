//
//  OnboardingView.swift
//  Chalkak
//
//  Created by Murphy on 8/12/25.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentIndex = 0
    
    var body: some View {
        ZStack {
            SnappieColor.darkHeavy.ignoresSafeArea()
            
            VStack {
                TabView(selection: $currentIndex) {
                    Onboard(systemImageName: "square.and.arrow.up.circle",
                            title: "첫 촬영으로 가이드 완성",
                            description: "원하는 장면을 찍으면 자동으로 \n촬영 가이드가 만들어져요.")
                    .tag(0)
                    
                    Onboard(systemImageName: "square.and.arrow.up.on.square.fill",
                            title: "촬영 직후 간단 편집",
                            description: "장면을 촬영할 때마다 \n길이만 간단히 조절하면 돼요.")
                    .tag(1)
                    
                    Onboard(systemImageName: "pencil.circle.fill",
                            title: "다 찍으면 영상 완성",
                            description: "원하는 장면을 다 찍고 종료하면 \n영상이 하나로 이어져 완성돼요.")
                    .tag(2)
                }
                .padding(.vertical, 48)
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // 세 번째 페이지에서만 dismiss 버튼 표시
                if currentIndex == 2 {
                    SnappieButton(.solidPrimary(
                        title: "시작하기",
                        size: .large
                    )) {
                        //                    dismiss()
                    }
                    .disabled(false)
                }
            }
        }
    }
}

struct Onboard: View {
    let systemImageName: String
    let title: String
    let description: String
    
    var body: some View {
        VStack() {
            Image(systemName: systemImageName)
            VStack (spacing: 12){
                Text(title)
                    .foregroundStyle(Color.matcha200)
                    .font(.title)
                    .fontWeight(.bold)
                Text(description)
                    .foregroundStyle(Color.matcha50)
                    .font(.body)
                    .multilineTextAlignment(.center)
            }
        }
    }
}


#Preview {
    OnboardingView()
}
