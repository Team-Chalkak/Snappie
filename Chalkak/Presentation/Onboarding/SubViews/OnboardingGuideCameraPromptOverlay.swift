//
//  OnboardingGuideCameraPromptOverlay.swift
//  Chalkak
//
//  Created by 배현진 on 6/28/26.
//

import SwiftUI

struct OnboardingGuideCameraPromptOverlay: View {
    let lines: [String]
    let frameImageNames: [String]
    let action: () -> Void

    var body: some View {
        ZStack {
            Color.black
                .opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 75) {
                VStack(spacing: 32) {
                    OnboardingFrameAnimationView(imageNames: frameImageNames)

                    VStack(spacing: 10) {
                        ForEach(lines, id: \.self) { line in
                            Text(line)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(SnappieColor.labelPrimaryNormal)
                                .multilineTextAlignment(.center)
                        }
                    }
                }

                OnboardingPrimaryButton(title: "확인", action: action)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
        }
    }
}
