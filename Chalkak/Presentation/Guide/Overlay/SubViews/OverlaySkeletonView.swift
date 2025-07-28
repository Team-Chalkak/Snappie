// OverlaySkeletonView.swift
import SwiftUI

struct OverlaySkeletonView: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let baseColor = SnappieColor.darkStrong
            let shimmerWidth = size.width
            let shimmerHeight = size.height
            let gradientLength = sqrt(shimmerWidth * shimmerWidth
                                   + shimmerHeight * shimmerHeight)

            let shimmer = LinearGradient(
                gradient: SnappieColor.gradientFillNormal,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: gradientLength, height: gradientLength)
            .rotationEffect(.degrees(Gradient.rotate))
            .offset(x: animate ? shimmerWidth * Gradient.multiplier : -shimmerWidth)
            .blur(radius: Gradient.radius)
            .animation(
                .linear(duration: Gradient.duration)
                  .repeatForever(autoreverses: false),
                value: animate
            )

            ZStack {
                skeletonBody
                  .foregroundColor(baseColor)
                  .overlay(shimmer)
                      .mask(skeletonBody)
            }
            .onAppear {
                animate = false
                DispatchQueue.main.async {
                    animate = true
                }
            }
        }
    }

    /// OverlayView와 똑같은 위치·크기·패딩으로 구성된 뼈대
    private var skeletonBody: some View {
        VStack(alignment: .center) {
            // 네비 바 백버튼 자리
            HStack {
                Circle()
                    .frame(width: Layout.navIconSize,
                           height: Layout.navIconSize)
                Spacer()
            }
            .padding(.horizontal, Layout.navHorizontalPadding)
            
            // 텍스트 타이틀 자리
            RoundedRectangle(cornerRadius: Layout.titleCorner)
                .frame(height: Layout.titleHeight)
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.bottom, Layout.verticalPadding)

            // 메인 이미지 자리
            RoundedRectangle(cornerRadius: Layout.displayCorner)
                .aspectRatio(
                    Layout.aspectRatioWidth / Layout.aspectRatioHeight,
                    contentMode: .fill
                )
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.bottom, Layout.displayBottomPadding)

            // 액션 버튼 자리
            RoundedRectangle(cornerRadius: Layout.buttonCorner)
                .frame(height: Layout.buttonHeight)
                .padding(.horizontal, Layout.buttonHorizontalPadding)
                .padding(.bottom, Layout.buttonBottomPadding)
        }
    }
}

private extension OverlaySkeletonView {
    enum Layout {
        // 네비 바 백버튼
        static let navIconSize: CGFloat = 32
        static let navHorizontalPadding: CGFloat = 16
        static let spacerHeight: CGFloat = 1

        // 타이틀
        static let titleHeight: CGFloat = 32
        static let titleCorner: CGFloat = 16

        // 메인 이미지
        static let displayCorner: CGFloat = 20
        static let aspectRatioWidth: CGFloat = 329
        static let aspectRatioHeight: CGFloat = 585
        static let displayBottomPadding: CGFloat = 20

        // 버튼
        static let buttonHeight: CGFloat = 48
        static let buttonCorner: CGFloat = 30
        static let buttonHorizontalPadding: CGFloat = 88
        static let buttonBottomPadding: CGFloat = 43
        
        static let horizontalPadding: CGFloat = 32
        static let verticalPadding: CGFloat = 8
    }
    
    enum Gradient {
        static let rotate: Double = 20
        static let multiplier: CGFloat = 3
        static let radius: Double = 150
        static let duration: Double = 1.2
    }
}
