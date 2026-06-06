//
//  OnboardingView.swift
//  Chalkak
//
//  Created by bishoe01 on 6/1/26.
//

import FirebaseAnalytics
import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @Environment(\.locale) private var locale

    var body: some View {
        if OnboardingAudience.usesKoreanOnboarding(locale: locale) {
            KoreanOnboardingFlowView(onComplete: onComplete)
        } else {
            LegacyOnboardingView(onComplete: onComplete)
        }
    }
}

private struct KoreanOnboardingFlowView: View {
    let onComplete: () -> Void

    @StateObject private var controller: OnboardingFlowController

    init(
        steps: [OnboardingStep] = OnboardingStep.activeSteps,
        onComplete: @escaping () -> Void
    ) {
        self.onComplete = onComplete
        _controller = StateObject(wrappedValue: OnboardingFlowController(steps: steps))
    }

    var body: some View {
        ZStack {
            SnappieColor.darkStrong.ignoresSafeArea()

            VStack(spacing: 0) {
                renderedStep

                if shouldShowPrimaryButton {
                    OnboardingPrimaryButton(
                        title: primaryButtonTitle,
                        horizontalPadding: primaryButtonHorizontalPadding
                    ) {
                        handlePrimaryAction()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: controller.currentStep)
        }
        .task(id: controller.currentStep) {
            await scheduleAutomaticAdvanceIfNeeded()
        }
    }

    @ViewBuilder
    private var renderedStep: some View {
        switch controller.currentStep {
        case .introExactComposition:
            OnboardingIconBeatStepView(
                lines: controller.currentStep.prompt(for: controller.selectedCarouselCard),
                imageName: "on_p",
                activeImageName: "on_p-active"
            )
        case .guideSimpleRecord:
            OnboardingIconBeatStepView(
                lines: controller.currentStep.prompt(for: controller.selectedCarouselCard),
                imageName: "on_c",
                activeImageName: "on_c-active"
            )
        case .dailyMemoryCarousel:
            OnboardingCarouselStepView(
                titleLines: controller.currentStep.prompt(for: controller.selectedCarouselCard),
                selectedCard: $controller.selectedCarouselCard
            )
        case .firstShootPrompt:
            OnboardingCenteredPromptStepView(
                lines: controller.currentStep.prompt(for: controller.selectedCarouselCard),
                buttonTitle: "확인"
            ) {
                handleCenteredPromptAction()
            }
        case .guideShootPrompt:
            OnboardingGuideShootPromptStepView(
                lines: controller.currentStep.prompt(for: controller.selectedCarouselCard),
                frameImageNames: (1...17).map { "c-\($0)" }
            ) {
                handleCenteredPromptAction()
            }
        case .shootDone:
            OnboardingTypingTextStepView(
                lines: controller.currentStep.prompt(for: controller.selectedCarouselCard)
            ) {
                controller.moveNext()
            }
        default:
            OnboardingTextStepView(lines: controller.currentStep.prompt(for: controller.selectedCarouselCard))
        }
    }

    private var shouldShowPrimaryButton: Bool {
        guard controller.currentStep != .firstShootPrompt,
              controller.currentStep != .guideShootPrompt,
              controller.currentStep != .shootDone else { return false }

        return switch controller.advanceBehavior {
        case .automatic:
            false
        case .typingAutomatic:
            false
        case .manual, .completion:
            true
        }
    }

    private var primaryButtonTitle: String {
        controller.isCompletionStep ? "완료" : "다음"
    }

    private var primaryButtonHorizontalPadding: CGFloat {
        controller.isCompletionStep ? 95 : 30
    }

    private func handlePrimaryAction() {
        if controller.isCompletionStep {
            onComplete()
            Analytics.logEvent("startButtonTapped", parameters: nil)
            return
        }

        if controller.currentStep == .firstShootPrompt {
            handleCenteredPromptAction()
            return
        }

        controller.moveNext()
    }

    private func handleCenteredPromptAction() {
        controller.moveNext()
    }

    private func scheduleAutomaticAdvanceIfNeeded() async {
        guard case .automatic(let delay) = controller.advanceBehavior else { return }

        do {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                controller.moveNext()
            }
        } catch {
            return
        }
    }
}

private struct LegacyOnboardingView: View {
    let onComplete: () -> Void

    @State private var currentIndex = 0
    @Environment(\.locale) private var locale

    private let items: [OnboardingItem] = [
        .init(
            id: 0,
            imageName: "OnboardingImage1",
            titleKey: "onboarding.step1.title",
            descriptionKey: "onboarding.step1.description"
        ),
        .init(
            id: 1,
            imageName: "OnboardingImage2",
            titleKey: "onboarding.step2.title",
            descriptionKey: "onboarding.step2.description"
        ),
        .init(
            id: 2,
            imageName: "OnboardingImage3",
            titleKey: "onboarding.step3.title",
            descriptionKey: "onboarding.step3.description"
        )
    ]

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

                if currentIndex == items.index(before: items.endIndex) {
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

    private func localizedImageName(base: String) -> String {
        "\(OnboardingAudience.usesKoreanOnboarding(locale: locale) ? "ko" : "en")\(base)"
    }
}

private struct OnboardingItem: Identifiable {
    let id: Int
    let imageName: String
    let titleKey: LocalizedStringKey
    let descriptionKey: LocalizedStringKey
}
