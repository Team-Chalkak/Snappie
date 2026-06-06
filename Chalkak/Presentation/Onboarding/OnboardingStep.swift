//
//  OnboardingStep.swift
//  Chalkak
//
//  Created by Codex on 6/1/26.
//

import Foundation

enum OnboardingAdvanceBehavior: Equatable {
    case automatic(delay: TimeInterval)
    case manual
    case completion
}

enum OnboardingAudience {
    static func usesKoreanOnboarding(locale: Locale) -> Bool {
        isKorean(languageCode: locale.language.languageCode)
    }

    static func isKorean(languageCode: Locale.LanguageCode?) -> Bool {
        languageCode == .korean
    }
}

enum OnboardingCarouselCard: Int, CaseIterable, Hashable, Identifiable {
    case first
    case second
    case third

    var id: Int { rawValue }

    var imageName: String {
        switch self {
        case .first:
            "onboarding1"
        case .second:
            "onboarding2"
        case .third:
            "onboarding3"
        }
    }

    var title: String {
        switch self {
        case .first:
            "나의 작은 친구 🧸"
        case .second:
            "손하트 영상 🔥"
        case .third:
            "소중한 사람과의 하루 💕"
        }
    }

    var caption: String {
        switch self {
        case .first:
            "키링, 인형, 소품들을 담아요"
        case .second:
            "귀여운 포즈를 남겨요"
        case .third:
            "연인, 가족, 반려동물과 함께"
        }
    }

    static func updateSelection(
        _ selectedCard: inout OnboardingCarouselCard,
        toCenteredCard centeredCard: OnboardingCarouselCard?,
        onChange: () -> Void
    ) {
        guard let centeredCard, centeredCard != selectedCard else { return }

        selectedCard = centeredCard
        onChange()
    }
}

enum OnboardingStep: CaseIterable, Equatable {
    case introExactComposition
    case guideSimpleRecord
    case dailyMemoryCarousel
    case firstShootPrompt
    case guideShootPrompt
    case shootDone
    case projectContinue

    static let activeSteps: [OnboardingStep] = [
        .introExactComposition,
        .guideSimpleRecord,
        .dailyMemoryCarousel,
        .firstShootPrompt,
        .guideShootPrompt,
        .shootDone,
        .projectContinue
    ]

    var advanceBehavior: OnboardingAdvanceBehavior {
        switch self {
        case .introExactComposition:
            .automatic(delay: 2.2)
        case .guideSimpleRecord:
            .automatic(delay: 3.0)
        case .dailyMemoryCarousel, .firstShootPrompt, .guideShootPrompt, .shootDone:
            .manual
        case .projectContinue:
            .completion
        }
    }

    func prompt(for selectedCard: OnboardingCarouselCard?) -> [String] {
        switch self {
        case .introExactComposition:
            [
                "구도는 정확하게",
                "편집은 간단하게"
            ]
        case .guideSimpleRecord:
            [
                "촬영 가이드로",
                "간편하게 기록해요"
            ]
        case .dailyMemoryCarousel:
            [
                "오늘 하루,",
                "무엇을 담아볼까요?"
            ]
        case .firstShootPrompt:
            switch selectedCard ?? .first {
            case .first:
                [
                    "작은 친구와 함께",
                    "첫 촬영을 시작해볼까요?"
                ]
            case .second:
                [
                    "귀여운 포즈로",
                    "첫 촬영을 시작해볼까요?"
                ]
            case .third:
                [
                    "소중한 사람과",
                    "첫 촬영을 시작해볼까요 ?"
                ]
            }
        case .guideShootPrompt:
            [
                "가이드에 맞춰",
                "다른 장면을 찍어주세요"
            ]
        case .shootDone:
            [
                "촬영끝!"
            ]
        case .projectContinue:
            [
                "나의 프로젝트에서",
                "오늘 하루를 계속 담아보세요"
            ]
        }
    }
}
