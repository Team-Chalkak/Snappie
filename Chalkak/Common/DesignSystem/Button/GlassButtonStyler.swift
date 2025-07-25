//
//  GlassButtonStyler.swift
//  Chalkak
//
//  Created by 석민솔 on 7/24/25.
//

import SwiftUI

// MARK: - Glass Pill Button Styler
struct GlassPillStyler: ButtonStyler {
    let contentType: ButtonContentType
    let isActive: Bool
    
    func height() -> CGFloat {
        ButtonSizeConstant.heightMini
    }
    
    func padding() -> EdgeInsets {
        switch contentType {
        case .text:
            EdgeInsets(
                top: 4,
                leading: 9,
                bottom: 4,
                trailing: 9
            )

        case .icon:
            EdgeInsets(
                top: 4,
                leading: 19,
                bottom: 4,
                trailing: 19
            )
        }
    }
    
    func background(isPressed: Bool, isEnabled: Bool) -> AnyView {
        return AnyView(
            ZStack {
                SnappieColor.darkHeavy.opacity(0.6)
                
                if isActive {
                    SnappieColor.darkHeavy.opacity(0.2)
                }
                
                LinearGradient(
                    gradient: SnappieColor.gradientFillNormal,
                    startPoint: UnitPoint(x: 0.03, y: 0.08),
                    endPoint: UnitPoint(x: 0.95, y: 0.96)
                )
            }
            .mask(Capsule())
        )
    }
    
    func foregroundColor(isPressed: Bool, isEnabled: Bool) -> Color {
        return isActive ? SnappieColor.labelPrimaryActive : SnappieColor.labelPrimaryNormal
    }
    
    func fontStyle() -> SnappieFont.Style {
        return .proLabel2
    }
    
    func iconScale() -> IconScale {
        return .medium
    }
}

// MARK: - Glass Ellipse Button Styler
struct GlassEllipseStyler: ButtonStyler {
    let contentType: ButtonContentType
    let isActive: Bool
    
    func height() -> CGFloat {
        ButtonSizeConstant.heightMini
    }
    
    func padding() -> EdgeInsets {
        return EdgeInsets(
            top: 4,
            leading: 4,
            bottom: 4,
            trailing: 4
        )
    }
    
    func background(isPressed: Bool, isEnabled: Bool) -> AnyView {
        return AnyView(
            ZStack {
                SnappieColor.darkHeavy.opacity(0.6)
                
                if isActive {
                    SnappieColor.darkHeavy.opacity(0.2)
                }
                
                LinearGradient(
                    gradient: SnappieColor.gradientFillNormal,
                    startPoint: UnitPoint(x: 0.03, y: 0.08),
                    endPoint: UnitPoint(x: 0.95, y: 0.96)
                )
            }
            .frame(width: height(), height: height())
            .mask(Circle())
        )
    }
    
    func foregroundColor(isPressed: Bool, isEnabled: Bool) -> Color {
        return isActive ? SnappieColor.labelPrimaryActive : SnappieColor.labelPrimaryNormal
    }
    
    func fontStyle() -> SnappieFont.Style {
        return .proLabel2
    }
    
    func iconScale() -> IconScale {
        return .medium
    }
}

