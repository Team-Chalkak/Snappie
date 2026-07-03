//
//  OnboardingSubView.swift
//  Chalkak
//
//  Created by bishoe01 on 6/1/26.
//

import SwiftUI
import UIKit

struct Onboard: View {
    let ImageName: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey

    var body: some View {
        VStack {
            Image(ImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 346)
                .padding(.bottom, 40)

            Text(title)
                .foregroundStyle(Color.matcha200)
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 12)

            Text(description)
                .foregroundStyle(Color.matcha50)
                .font(.body)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .frame(height: 80, alignment: .top)
        }
    }
}

struct OnboardingBrandBeatStepView: View {
    let lines: [String]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(SnappieColor.labelPrimaryNormal)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }
}

struct OnboardingIconBeatStepView: View {
    let lines: [String]
    let imageName: String
    let activeImageName: String
    var loopTiming: OnboardingIconLoopTiming = .iconBeat

    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 36) {
            OnboardingLoopingIconView(
                imageName: imageName,
                activeImageName: activeImageName,
                timing: loopTiming
            )

            VStack(spacing: 10) {
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(SnappieColor.labelPrimaryNormal)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .opacity(isVisible ? 1 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
        .task {
            await runGuideIconAnimation()
        }
    }

    private func runGuideIconAnimation() async {
        await Task.yield()

        await MainActor.run {
            withAnimation(.easeIn(duration: 0.4)) {
                isVisible = true
            }
        }

        do {
            try await Task.sleep(nanoseconds: 400_000_000)
        } catch {
            return
        }
    }
}

struct OnboardingIconLoopTiming {
    var defaultStateHold: Duration
    var activeStateHold: Duration
    var activate: Animation
    var deactivate: Animation

    static let iconBeat = OnboardingIconLoopTiming(
        defaultStateHold: .milliseconds(600),
        activeStateHold: .milliseconds(800),
        activate: .easeIn(duration: 0.2),
        deactivate: .easeIn(duration: 0.3)
    )
}

struct OnboardingLoopingIconView: View {
    let imageName: String
    let activeImageName: String
    var timing: OnboardingIconLoopTiming = .iconBeat

    @State private var showsActiveImage = false

    var body: some View {
        ZStack {
            // 카메라(점 없음) 베이스 — 항상 켜둬서 몸통이 흔들리지 않음
            Image(imageName)
                .resizable()
                .scaledToFit()

            // 카메라+빨간 점 — 이 레이어만 페이드해서 점만 깜빡이도록
            Image(activeImageName)
                .resizable()
                .scaledToFit()
                .opacity(showsActiveImage ? 1 : 0)
        }
        .frame(width: 72, height: 72)
        .task {
            await runIconLoop()
        }
    }

    private func runIconLoop() async {
        while !Task.isCancelled {
            // 기본 상태 유지 후 빨간 점으로 전환
            guard await wait(timing.defaultStateHold) else { return }
            await setActive(true, animation: timing.activate)

            // 빨간 점 상태 유지 후 기본으로 전환
            guard await wait(timing.activeStateHold) else { return }
            await setActive(false, animation: timing.deactivate)
        }
    }

    private func wait(_ duration: Duration) async -> Bool {
        do {
            try await Task.sleep(for: duration)
        } catch {
            return false
        }
        return !Task.isCancelled
    }

    private func setActive(_ isActive: Bool, animation: Animation) async {
        await MainActor.run {
            withAnimation(animation) {
                showsActiveImage = isActive
            }
        }
    }
}

/// 이미지 전환 없이 단일 이미지만 은은하게 호흡시키는 비트 뷰 (스텝 1)
struct OnboardingFadeBeatStepView: View {
    let lines: [String]
    let imageName: String
    var timing: OnboardingIconLoopTiming = .iconBeat
    var dimmedOpacity: Double = 0.4

    @State private var isBright = true

    var body: some View {
        VStack(spacing: 36) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .opacity(isBright ? 1 : dimmedOpacity)

            VStack(spacing: 10) {
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(SnappieColor.labelPrimaryNormal)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
        .task {
            await runFadeLoop()
        }
    }

    private func runFadeLoop() async {
        while !Task.isCancelled {
            // 선명한 상태 유지 후 흐려짐
            guard await wait(timing.activeStateHold) else { return }
            await setBright(false, animation: timing.deactivate)

            // 흐린 상태 유지 후 다시 선명해짐
            guard await wait(timing.defaultStateHold) else { return }
            await setBright(true, animation: timing.activate)
        }
    }

    private func wait(_ duration: Duration) async -> Bool {
        do {
            try await Task.sleep(for: duration)
        } catch {
            return false
        }
        return !Task.isCancelled
    }

    private func setBright(_ isBrightState: Bool, animation: Animation) async {
        await MainActor.run {
            withAnimation(animation) {
                isBright = isBrightState
            }
        }
    }
}

struct OnboardingTextStepView: View {
    let lines: [String]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(SnappieColor.labelPrimaryNormal)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }
}

struct OnboardingTypingTextStepView: View {
    let lines: [String]
    let characterDelay: UInt64
    let completionDelay: UInt64
    let onFinished: () -> Void

    @State private var displayedLines: [String] = []
    @State private var activeLineIndex: Int?

    init(
        lines: [String],
        characterDelay: UInt64 = 120_000_000,
        completionDelay: UInt64 = 700_000_000,
        onFinished: @escaping () -> Void
    ) {
        self.lines = lines
        self.characterDelay = characterDelay
        self.completionDelay = completionDelay
        self.onFinished = onFinished
    }

    var body: some View {
        VStack(spacing: 10) {
            ForEach(lines.indices, id: \.self) { index in
                Text(displayedLine(at: index) + cursorSuffix(for: index))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(SnappieColor.labelPrimaryNormal)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
        .task(id: lines.joined(separator: "\n")) {
            await runTypingAnimation()
        }
    }

    private func displayedLine(at index: Int) -> String {
        guard displayedLines.indices.contains(index) else { return "" }
        return displayedLines[index]
    }

    private func cursorSuffix(for index: Int) -> String {
        activeLineIndex == index ? "|" : ""
    }

    private func runTypingAnimation() async {
        await MainActor.run {
            displayedLines = lines.map { _ in "" }
            activeLineIndex = lines.isEmpty ? nil : lines.startIndex
        }

        for lineIndex in lines.indices {
            await MainActor.run {
                activeLineIndex = lineIndex
            }

            for character in lines[lineIndex] {
                do {
                    try await Task.sleep(nanoseconds: characterDelay)
                } catch {
                    return
                }

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    displayedLines[lineIndex].append(character)
                }
            }
        }

        await MainActor.run {
            activeLineIndex = nil
        }

        do {
            try await Task.sleep(nanoseconds: completionDelay)
        } catch {
            return
        }

        guard !Task.isCancelled else { return }

        await MainActor.run {
            onFinished()
        }
    }
}

struct OnboardingCenteredPromptStepView: View {
    let lines: [String]
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 75) {
            VStack(spacing: 10) {
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(SnappieColor.labelPrimaryNormal)
                        .multilineTextAlignment(.center)
                }
            }

            OnboardingPrimaryButton(title: buttonTitle, action: action)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }
}

struct OnboardingGuideShootPromptStepView: View {
    let lines: [String]
    let action: () -> Void

    var body: some View {
        VStack(spacing: 75) {
            VStack(spacing: 32) {
                OnboardingTiltCircleAnimationView()

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

struct OnboardingTiltCircleAnimationView: View {
    private enum Phase {
        case start
        case halfOverlapped
        case attached

        var innerCircleCenter: CGPoint {
            switch self {
            case .start:
                CGPoint(x: 15, y: 15)
            case .halfOverlapped:
                CGPoint(x: 33, y: 33)
            case .attached:
                CGPoint(x: 45, y: 45)
            }
        }
    }

    private let designSize: CGFloat = 69
    private let renderedSize: CGFloat = 30
    private let outerCircleCenter = CGPoint(x: 45, y: 45)
    private let outerCircleDiameter: CGFloat = 37
    private let innerCircleDiameter: CGFloat = 24
    private let fadeOutDuration = 0.1
    private let firstMoveDuration = 0.35
    private let secondMoveDuration = 0.15

    @State private var phase: Phase = .start
    @State private var isVisible = true

    var body: some View {
        ZStack(alignment: .topLeading) {
            Circle()
                .stroke(SnappieColor.primaryNormal.opacity(0.32), lineWidth: 2)
                .frame(width: outerCircleDiameter + 7, height: outerCircleDiameter + 7)
                .position(outerCircleCenter)

            Circle()
                .stroke(SnappieColor.primaryNormal, lineWidth: 5)
                .frame(width: outerCircleDiameter, height: outerCircleDiameter)
                .position(outerCircleCenter)

            Circle()
                .fill(SnappieColor.primaryNormal)
                .frame(width: innerCircleDiameter, height: innerCircleDiameter)
                .position(phase.innerCircleCenter)
        }
        .frame(width: designSize, height: designSize)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(renderedSize / designSize)
        .frame(width: renderedSize, height: renderedSize)
        .task {
            await runTiltLoop()
        }
    }

    private func runTiltLoop() async {
        await reset()
        var shouldWaitBeforeNextMove = true

        while !Task.isCancelled {
            if shouldWaitBeforeNextMove {
                guard await wait(.milliseconds(400)) else { return }
                await setPhase(.halfOverlapped, animation: .easeIn(duration: firstMoveDuration))
            } else {
                await reappearAndMoveToHalfOverlapped()
            }

            guard await wait(.milliseconds(350)) else { return }
            await setPhase(.attached, animation: .easeIn(duration: secondMoveDuration))
            guard await wait(.milliseconds(150)) else { return }

            guard await wait(.milliseconds(200)) else { return }
            await setVisible(false, animation: .linear(duration: fadeOutDuration))
            guard await wait(.milliseconds(100)) else { return }

            guard await wait(.milliseconds(200)) else { return }
            shouldWaitBeforeNextMove = false
        }
    }

    private func wait(_ duration: Duration) async -> Bool {
        do {
            try await Task.sleep(for: duration)
        } catch {
            return false
        }
        return !Task.isCancelled
    }

    private func reset() async {
        await MainActor.run {
            phase = .start
            isVisible = true
        }
    }

    private func setPhase(_ newPhase: Phase, animation: Animation) async {
        await MainActor.run {
            withAnimation(animation) {
                phase = newPhase
            }
        }
    }

    private func reappearAndMoveToHalfOverlapped() async {
        await MainActor.run {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                phase = .start
                isVisible = true
            }

            withAnimation(.easeIn(duration: firstMoveDuration)) {
                phase = .halfOverlapped
            }
        }
    }

    private func setVisible(_ visible: Bool, animation: Animation) async {
        await MainActor.run {
            withAnimation(animation) {
                isVisible = visible
            }
        }
    }
}

struct OnboardingCarouselStepView: View {
    let titleLines: [String]
    private let onCenteredCardChange: () -> Void
    @Binding var selectedCard: OnboardingCarouselCard
    @State private var scrollPosition: OnboardingCarouselCard?

    init(
        titleLines: [String],
        selectedCard: Binding<OnboardingCarouselCard>,
        onCenteredCardChange: @escaping () -> Void = {
            UISelectionFeedbackGenerator().selectionChanged()
        }
    ) {
        self.titleLines = titleLines
        self._selectedCard = selectedCard
        self.onCenteredCardChange = onCenteredCardChange
    }

    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 10) {
                ForEach(titleLines, id: \.self) { line in
                    Text(line)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(SnappieColor.labelPrimaryNormal)
                        .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: 10) {
                GeometryReader { geometry in
                    let cardWidth = min(304, geometry.size.width - 84)
                    let sidePeek = max(24, (geometry.size.width - cardWidth) / 2)

                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 16) {
                            ForEach(OnboardingCarouselCard.allCases) { card in
                                OnboardingPhotoCard(
                                    card: card,
                                    isSelected: card == selectedCard
                                )
                                .frame(width: cardWidth)
                                .id(card)
                                .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                    content
                                        .scaleEffect(phase.isIdentity ? 1 : 0.9)
                                        .opacity(phase.isIdentity ? 1 : 0.55)
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .contentMargins(.horizontal, sidePeek, for: .scrollContent)
                    .scrollPosition(id: $scrollPosition)
                    .scrollTargetBehavior(.viewAligned)
                    .scrollIndicators(.hidden)
                }
                .frame(height: 474)

                HStack(spacing: 8) {
                    ForEach(OnboardingCarouselCard.allCases) { card in
                        Circle()
                            .fill(card == selectedCard ? SnappieColor.primaryNormal : SnappieColor.darkNormal)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 92)
        .padding(.bottom, 76)
        .onAppear {
            scrollPosition = selectedCard
        }
        .onChange(of: selectedCard) { _, newValue in
            scrollPosition = newValue
        }
        .onChange(of: scrollPosition) { _, newValue in
            OnboardingCarouselCard.updateSelection(
                &selectedCard,
                toCenteredCard: newValue,
                onChange: onCenteredCardChange
            )
        }
    }
}

private struct OnboardingPhotoCard: View {
    let card: OnboardingCarouselCard
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text(card.title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(SnappieColor.labelPrimaryNormal)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)

            Image(card.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 190, height: 338)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .clipped()

            Text(card.caption)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(SnappieColor.labelPrimaryNormal)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 30)
        .frame(height: 474)
        .background(SnappieColor.darkNormal.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(SnappieColor.primaryNormal, lineWidth: 2)
            }
        }
    }
}

struct OnboardingPrimaryButton: View {
    let title: String
    let horizontalPadding: CGFloat
    let action: () -> Void

    init(
        title: String,
        horizontalPadding: CGFloat = 30,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.horizontalPadding = horizontalPadding
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(SnappieColor.labelDarkNormal)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 16)
                .background(SnappieColor.primaryNormal)
                .cornerRadius(99)
        }
    }
}

#Preview("Onboarding text") {
    ZStack {
        SnappieColor.darkStrong.ignoresSafeArea()
        OnboardingBrandBeatStepView(lines: [
            "구도는 정확하게",
            "편집은 간단하게"
        ])
    }
}

#Preview("Onboarding carousel") {
    ZStack {
        SnappieColor.darkStrong.ignoresSafeArea()
        OnboardingCarouselStepView(
            titleLines: [
                "오늘 하루,",
                "무엇을 담아볼까요?"
            ],
            selectedCard: .constant(.first)
        )
    }
}

#Preview("Onboarding primary button") {
    ZStack {
        SnappieColor.darkStrong.ignoresSafeArea()
        VStack {
            Spacer()
            OnboardingPrimaryButton(title: "다음") {}
                .padding(24)
        }
    }
}

#Preview("Onboarding centered prompt") {
    ZStack {
        SnappieColor.darkStrong.ignoresSafeArea()
        OnboardingCenteredPromptStepView(
            lines: [
                "작은 친구와 함께",
                "첫 촬영을 시작해볼까요?"
            ],
            buttonTitle: "확인"
        ) {}
    }
}
