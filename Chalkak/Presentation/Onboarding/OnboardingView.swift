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
                    OnboardingPrimaryButton(title: primaryButtonTitle) {
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
        default:
            OnboardingTextStepView(lines: controller.currentStep.prompt(for: controller.selectedCarouselCard))
        }
    }

    private var shouldShowPrimaryButton: Bool {
        guard controller.currentStep != .firstShootPrompt,
              controller.currentStep != .guideShootPrompt else { return false }

        return switch controller.advanceBehavior {
        case .automatic:
            false
        case .manual, .completion:
            true
        }
    }

    private var primaryButtonTitle: String {
        controller.isCompletionStep ? "시작하기" : "다음"
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
