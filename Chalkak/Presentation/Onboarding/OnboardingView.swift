//
//  OnboardingVied.swift
//  Chalkak
//
//  Created by Murphy on 8/12/25.
//

import FirebaseAnalytics
import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var currentIndex = 0
    @Environment(\.locale) private var locale
    
    private let items: [OnboardingItem] = [
        .init(
            id: 0,
            imageName: "OnboardingImage1",
            titleKey: "onboarding.step1.title",
            descriptionKey: "onboarding.step1.description"),
        .init(
            id: 1,
            imageName: "OnboardingImage2",
            titleKey: "onboarding.step2.title",
            descriptionKey: "onboarding.step2.description"),
        .init(
            id: 2,
            imageName: "OnboardingImage3",
            titleKey: "onboarding.step3.title",
            descriptionKey: "onboarding.step3.description")
    ]
    
    private var isKorean: Bool {
        let langCode = locale.language.languageCode?.identifier ?? ""
        return langCode.lowercased().hasPrefix("ko")
    }
    
    private func localizedImageName(base: String) -> String {
        "\(isKorean ? "ko" : "en")\(base)"
    }
    
    var body: some View {
        ZStack {
            SnappieColor.darkStrong.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(items) { item in
                    Onboard(
                        ImageName: localizedImageName(base: item.imageName),
                        title: item.titleKey,
                        description: item.descriptionKey
                    )
                    .tag(item.id)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 48)
            .padding(.bottom, 56)
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack {
                Spacer()

                if currentIndex == 2 {
                    Button("시작하기") {
                        onComplete()
                        Analytics.logEvent("startButtonTapped", parameters: nil)
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

private struct OnboardingItem: Identifiable {
    let id: Int
    let imageName: String
    let titleKey: LocalizedStringKey
    let descriptionKey: LocalizedStringKey
}
