//
//  OnboardingSubView.swift
//  Chalkak
//
//  Created by bishoe01 on 6/1/26.
//

import SwiftUI

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

struct OnboardingGuideRecordStepView: View {
    let lines: [String]
    @State private var isVisible = false
    @State private var showsActiveIcon = false

    var body: some View {
        VStack(spacing: 36) {
            ZStack {
                Image("on_c")
                    .resizable()
                    .scaledToFit()
                    .opacity(showsActiveIcon ? 0 : 1)

                Image("on_c-active")
                    .resizable()
                    .scaledToFit()
                    .opacity(showsActiveIcon ? 1 : 0)
            }
            .frame(width: 72, height: 72)

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

        while !Task.isCancelled {
            do {
                try await Task.sleep(nanoseconds: 520_000_000)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showsActiveIcon.toggle()
                }
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

struct OnboardingCarouselStepView: View {
    let titleLines: [String]
    @Binding var selectedCard: OnboardingCarouselCard
    @State private var scrollPosition: OnboardingCarouselCard?

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
            guard let newValue else { return }
            selectedCard = newValue
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(SnappieColor.labelDarkNormal)
                .padding(.horizontal, 30)
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
