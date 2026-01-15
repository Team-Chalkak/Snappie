//
//  StartProjectView.swift
//  Chalkak
//
//  Created by bishoe01 on 12/15/25.
//

import SwiftUI
import TipKit

struct StartProjectView: View {
    @EnvironmentObject private var coordinator: Coordinator
    
    private let projectAddClipTip = ProjectAddClip()
    private let clipWidth: CGFloat = 62
    private let clipHeight: CGFloat = 97
    private let clipRadius: CGFloat = 8
    
    var body: some View {
        ZStack {
            SnappieColor.darkHeavy
                .ignoresSafeArea()
            
            VStack(spacing: 8) {
                SnappieNavigationBar(
                    leftButtonType: .backward {
                        coordinator.popLast()
                    },
                    rightButtonType: .twoButton(
                        primary: .init(label: "저장", isEnabled: false) {},
                        secondary: .init(icon: .export, isEnabled: false) {}
                    )
                )
                
                ZStack(alignment: .center) {
                    Rectangle()
                        .fill(SnappieColor.gradientFillNormal)
                        .cornerRadius(16)

                    Text("추가된 영상이 없습니다.")
                        .snappieStyle(.proBody1)
                        .foregroundStyle(SnappieColor.labelPrimaryNormal)
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(9.0 / 16.0, contentMode: .fit)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                VStack {
                    HStack {
                        SnappieButton(
                            .iconBackground(
                                icon: .playFill,
                                size: .medium,
                                isActive: false
                            )
                        ) {}
                        Spacer()
                        HStack(alignment: .center, spacing: 2) {
                            Text("00:00")
                            Text("/")
                                .foregroundStyle(SnappieColor.labelPrimaryDisable)
                            Text("00:00")
                                .foregroundStyle(SnappieColor.labelPrimaryDisable)
                        }.font(SnappieFont.style(.proCaption1))

                        Spacer()
                        SnappieButton(
                            .iconBackground(
                                icon: .silhouette,
                                size: .medium,
                                isActive: false
                            )
                        ) {}
                    }
                    .padding(.horizontal, 24)

                    // 구분선
                    Rectangle()
                        .fill(.deepGreen600)
                        .frame(maxWidth: .infinity, maxHeight: 1.5)
                        .padding(.vertical, 8)
                    
                    ZStack {
                        // 색상 배경
                        Rectangle()
                            .fill(SnappieColor.containerFillNormal)
                            .frame(maxWidth: .infinity)
                            .frame(height: clipHeight)
                        
                        // 촬영 버튼
                        Button {
                            coordinator.push(.camera(state: .firstShoot))
                        }
                        label: {
                            IconView(iconType: .camera, scale: .xlarge)
                                .foregroundStyle(SnappieColor.labelPrimaryNormal)
                                .frame(width: clipWidth, height: clipHeight)
                                .background(
                                    RoundedRectangle(cornerRadius: clipRadius)
                                        .fill(.deepGreen400)
                                )
                        }
                        .popoverTip(projectAddClipTip)
                        .offset(x: clipWidth / 2)
                        
                        // Playhead
                        PlayheadView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
    }
}

struct ProjectAddClip: Tip {
    var title: Text {
        Text("클립 추가 방법")
            .foregroundStyle(.matcha600)
    }

    var message: Text? {
        Text("버튼을 눌러서 촬영을 시작하세요.")
            .foregroundStyle(.matcha400)
    }

    var options: [TipOption] {
        Tips.MaxDisplayCount(1)
    }
}
