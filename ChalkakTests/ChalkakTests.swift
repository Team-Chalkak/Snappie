//
//  ChalkakTests.swift
//  ChalkakTests
//
//  Created by 배현진 on 7/11/25.
//

import Testing
import Foundation
@testable import Chalkak

struct ChalkakTests {

    @Test func boundingBoxInfoPreservesNonSquareHeight() {
        let box = BoundingBoxInfo(
            origin: PointWrapper(CGPoint(x: 0.2, y: 0.1)),
            scale: 0.25,
            height: 0.75
        )

        #expect(box.cgRect == CGRect(x: 0.2, y: 0.1, width: 0.25, height: 0.75))
    }

    @Test func boundingBoxInfoFallsBackToScaleForLegacyBoxes() {
        let legacyBox = BoundingBoxInfo(
            origin: PointWrapper(CGPoint(x: 0.2, y: 0.1)),
            scale: 0.25
        )

        #expect(legacyBox.cgRect == CGRect(x: 0.2, y: 0.1, width: 0.25, height: 0.25))
    }

    @Test func compareUsesCenterSoSmallOriginJitterStillAligns() {
        let viewModel = BoundingBoxViewModel()
        viewModel.referenceBoundingBoxes = [
            CGRect(x: 0.20, y: 0.10, width: 0.25, height: 0.75)
        ]
        viewModel.liveBoundingBoxes = [
            CGRect(x: 0.145, y: 0.205, width: 0.36, height: 0.54)
        ]

        viewModel.compare()

        #expect(viewModel.isAligned)
    }

    @Test func onboardingFlowMovesThroughOnlyActiveSteps() {
        let controller = OnboardingFlowController()

        #expect(controller.currentStep == .introExactComposition)

        controller.moveNext()
        #expect(controller.currentStep == .guideSimpleRecord)

        controller.moveNext()
        #expect(controller.currentStep == .dailyMemoryCarousel)

        controller.moveNext()
        #expect(controller.currentStep == .firstShootPrompt)

        controller.moveNext()
        #expect(controller.currentStep == .guideShootPrompt)

        controller.moveNext()
        #expect(controller.currentStep == .shootDone)

        controller.moveNext()
        #expect(controller.currentStep == .projectContinue)
    }

    @Test func onboardingCompletionStepDoesNotMoveNext() {
        let controller = OnboardingFlowController(steps: [.projectContinue])

        #expect(controller.isCompletionStep)
        controller.moveNext()

        #expect(controller.currentStep == .projectContinue)
        #expect(controller.isCompletionStep)
    }

    @Test func shootDoneStepUsesTypingAutomaticAdvance() {
        let controller = OnboardingFlowController(steps: [.shootDone, .projectContinue])

        #expect(controller.currentStep == .shootDone)
        #expect(controller.advanceBehavior == .typingAutomatic)
        #expect(controller.currentStep.prompt(for: nil) == ["촬영끝!"])

        controller.moveNext()

        #expect(controller.currentStep == .projectContinue)
        #expect(controller.currentStep.prompt(for: nil) == [
            "나의 프로젝트에서",
            "오늘 하루를 완성해보세요"
        ])
    }

    @Test func onboardingFirstShootPromptUsesSelectedCarouselCard() {
        let controller = OnboardingFlowController()

        controller.selectedCarouselCard = .second
        #expect(OnboardingStep.firstShootPrompt.prompt(for: controller.selectedCarouselCard) == [
            "귀여운 포즈로",
            "첫 촬영을 시작해볼까요?"
        ])

        controller.selectedCarouselCard = .third
        #expect(OnboardingStep.firstShootPrompt.prompt(for: controller.selectedCarouselCard) == [
            "소중한 사람과",
            "첫 촬영을 시작해볼까요 ?"
        ])
    }

    @Test func onboardingCarouselSelectionChangeFiresOnlyWhenCenteredCardChanges() {
        var selectedCard = OnboardingCarouselCard.first
        var changeCount = 0

        OnboardingCarouselCard.updateSelection(
            &selectedCard,
            toCenteredCard: nil
        ) {
            changeCount += 1
        }

        OnboardingCarouselCard.updateSelection(
            &selectedCard,
            toCenteredCard: .first
        ) {
            changeCount += 1
        }

        OnboardingCarouselCard.updateSelection(
            &selectedCard,
            toCenteredCard: .second
        ) {
            changeCount += 1
        }

        #expect(selectedCard == .second)
        #expect(changeCount == 1)
    }

    @Test func onboardingAudienceUsesKoreanFlowOnlyForKoreanLanguageCodes() {
        #expect(OnboardingAudience.usesKoreanOnboarding(locale: Locale(identifier: "ko")))
        #expect(OnboardingAudience.usesKoreanOnboarding(locale: Locale(identifier: "ko-KR")))
        #expect(OnboardingAudience.usesKoreanOnboarding(locale: Locale(identifier: "ko_KR")))

        #expect(!OnboardingAudience.usesKoreanOnboarding(locale: Locale(identifier: "en")))
        #expect(!OnboardingAudience.usesKoreanOnboarding(locale: Locale(identifier: "ja")))
    }

    @Test func onboardingNotificationScheduleEndsBeforeMidnightWhenStartedBeforeEvening() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let startDate = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 6, hour: 15, minute: 30)))

        let dates = OnboardingNotificationSchedulePolicy.scheduledDates(
            from: startDate,
            calendar: calendar
        )

        #expect(dates.count == 8)
        #expect(dates.first == calendar.date(from: DateComponents(year: 2026, month: 6, day: 6, hour: 16, minute: 30)))
        #expect(dates.last == calendar.date(from: DateComponents(year: 2026, month: 6, day: 6, hour: 23, minute: 30)))
    }

    @Test func onboardingNotificationScheduleRunsUntilSameTimeNextDayWhenStartedAfterEvening() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let startDate = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 6, hour: 18, minute: 20)))

        let dates = OnboardingNotificationSchedulePolicy.scheduledDates(
            from: startDate,
            calendar: calendar
        )

        #expect(dates.count == 24)
        #expect(dates.first == calendar.date(from: DateComponents(year: 2026, month: 6, day: 6, hour: 19, minute: 20)))
        #expect(dates.last == calendar.date(from: DateComponents(year: 2026, month: 6, day: 7, hour: 18, minute: 20)))
    }
}
