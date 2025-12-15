//
//  StartProjectView.swift
//  Chalkak
//
//  Created by bishoe01 on 12/15/25.
//

import SwiftUI

struct StartProjectView: View {
    @EnvironmentObject private var coordinator: Coordinator
    var body: some View {
        ZStack {
            SnappieColor.darkHeavy
                .ignoresSafeArea()
            VStack(spacing: 8) {
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
                        }.font(.system(size: 14, weight: .regular))

                        Spacer()
                        SnappieButton(
                            .iconBackground(
                                icon: .silhouette,
                                size: .medium,
                                isActive: false
                            )
                        ) {}
                    }

                    HStack(spacing: 4) {
//                        Play선의 필요성에 대한 고찰
//                        RoundedRectangle(cornerRadius: 2)
//                            .stroke(.white, lineWidth: 1)
//                            .frame(width: 1, height: 110)

                        Button {
                            coordinator.push(.camera(state: .firstShoot))
                        }
                        label: {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 25, weight: .regular))
                                .foregroundStyle(SnappieColor.labelDarkNormal)
                                .padding(.horizontal, 16)
                                .frame(height: 100)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(SnappieColor.primaryLight)
                                )
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}
