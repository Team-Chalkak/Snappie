//
//  OnboardingFlowController.swift
//  Chalkak
//
//  Created by bishoe01 on 6/1/26.
//

import Foundation

final class OnboardingFlowController: ObservableObject {
    let steps: [OnboardingStep]

    @Published private(set) var currentIndex: Int
    @Published var selectedCarouselCard: OnboardingCarouselCard
    @Published var experienceGuide: Guide?

    init(
        steps: [OnboardingStep] = OnboardingStep.activeSteps,
        selectedCarouselCard: OnboardingCarouselCard = .first
    ) {
        self.steps = steps.isEmpty ? OnboardingStep.activeSteps : steps
        self.currentIndex = 0
        self.selectedCarouselCard = selectedCarouselCard
    }

    var currentStep: OnboardingStep {
        steps[currentIndex]
    }

    var advanceBehavior: OnboardingAdvanceBehavior {
        currentStep.advanceBehavior
    }

    var isFirstStep: Bool {
        currentIndex == steps.startIndex
    }

    var isLastStep: Bool {
        currentIndex == steps.index(before: steps.endIndex)
    }

    var canMoveNext: Bool {
        !isLastStep
    }

    var isCompletionStep: Bool {
        advanceBehavior == .completion
    }

    func moveNext() {
        guard canMoveNext, !isCompletionStep else { return }
        currentIndex += 1
    }

    func moveBack() {
        guard !isFirstStep else { return }
        currentIndex -= 1
    }
}
