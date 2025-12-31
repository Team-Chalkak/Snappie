//
//  ToolButtonView.swift
//  Chalkak
//
//  Created by 석민솔 on 12/29/25.
//
import SwiftUI


struct ToolButtonView: View {
    let buttonStyle: ToolbarButtonStyle
    let onTapped: () -> Void
    
    private let buttonWidth: CGFloat = 52
    private let buttonHeight: CGFloat = 40

    var body: some View {
        VStack (spacing: 6) {
            Button {
                onTapped()
            } label: {
                Group {
                    switch buttonStyle {
                    case .editClip:
                        Image(systemName: "timeline.selection")
                            .font(.system(size: 18))
                            .foregroundStyle(SnappieColor.labelPrimaryNormal)
                    case .editGuide:
                        IconView(iconType: .silhouette, scale: .xlarge)
                            .foregroundStyle(SnappieColor.labelPrimaryNormal)
                    case .deleteClip:
                        Image(systemName: "trash")
                            .font(.system(size: 18))
                            .foregroundStyle(SnappieColor.labelPrimaryNormal)
                    }
                }
                .frame(width: buttonWidth, height: buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundStyle(SnappieColor.containerFillNormal)
                )

            }
            
            Text(buttonStyle.label)
                .font(.caption2)
                .foregroundStyle(.matcha50)
        }
    }
}
