//
//  OnboardingView.swift
//  Chalkak
//
//  Created by Murphy on 8/12/25.
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var cameraManager: CameraManager
    @State private var currentIndex = 0
//    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            SnappieColor.darkStrong.ignoresSafeArea()
            
            
            TabView(selection: $currentIndex) {
                Onboard(ImageName: "onboard_image1",
                        title: "첫 촬영으로 가이드 완성",
                        description: "원하는 장면을 찍으면 자동으로 \n촬영 가이드가 만들어져요.")
                .tag(0)
                
                Onboard(ImageName: "onboard_image2",
                        title: "촬영 직후 간단 편집",
                        description: "장면을 촬영할 때마다 \n길이만 간단히 조절하면 돼요.")
                .tag(1)
                
                Onboard(ImageName: "onboard_image3",
                        title: "다 찍으면 영상 완성",
                        description: "원하는 장면을 다 찍고 종료하면 \n영상이 하나로 이어져 완성돼요.")
                .tag(2)
            }
            .padding(.vertical, 48)
            .padding(.bottom, 56)
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
    
            VStack {
                Spacer()
                
                if currentIndex == 2 {
                    Button("시작하기") {
                        cameraManager.completeOnboarding()
                    }
                    .font(.headline)
                    .foregroundColor(SnappieColor.labelDarkNormal)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(SnappieColor.primaryNormal)
                    .cornerRadius(99)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: currentIndex)
                }
            }
        }
    }
}

struct Onboard: View {
    let ImageName: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 40) {
            Image(ImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 346)
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


//#Preview {
//    OnboardingView()
//}
