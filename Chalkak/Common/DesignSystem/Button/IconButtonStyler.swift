//
//  IconButtonStyler.swift
//  Chalkak
//
//  Created by 석민솔 on 7/24/25.
//

import SwiftUI

// MARK: - Icon Normal Button Styler
struct IconNormalStyler: ButtonStyler {
    let size: ButtonSizeType
    
    func height() -> CGFloat {
        size == .large
        ? ButtonSizeConstant.heightMedium
        : ButtonSizeConstant.heightSmall
    }
    
    func padding() -> EdgeInsets {
        return EdgeInsets(
            top: 8,
            leading: 8,
            bottom: 8,
            trailing: 8
        )
    }
    
    func background(isPressed: Bool, isEnabled: Bool) -> AnyView {
        let backgroundColor = isPressed ? SnappieColor.primaryNormal.opacity(0.1) : Color.clear
        
        return AnyView(
            Circle()
                .fill(backgroundColor)
        )
    }
    
    func foregroundColor(isPressed: Bool, isEnabled: Bool) -> Color {
        guard isEnabled else { return Color.gray }
        return isEnabled ? SnappieColor.labelPrimaryNormal : SnappieColor.labelPrimaryDisable
    }
    
    func fontStyle() -> SnappieFont.Style {
        return .proLabel1
    }
    
    func iconScale() -> IconScale {
        return size == .large ? .xlarge : .large
    }
}

// MARK: - Icon Solid Button Styler
struct IconSolidStyler: ButtonStyler {
    let size: ButtonSizeType
    
    func height() -> CGFloat {
        size == .large
        ? ButtonSizeConstant.heightMedium
        : ButtonSizeConstant.heightSmall
    }
    
    func padding() -> EdgeInsets {
        return EdgeInsets(
            top: 8,
            leading: 8,
            bottom: 8,
            trailing: 8
        )
    }
    
    func background(isPressed: Bool, isEnabled: Bool) -> AnyView {
        let backgroundColor = iconSolidBackgroundColor(isPressed: isPressed, isEnabled: isEnabled)
        
        return AnyView(
            Circle()
                .fill(backgroundColor)
        )
    }
    
    func foregroundColor(isPressed: Bool, isEnabled: Bool) -> Color {
        guard isEnabled else { return Color.gray }
        return isEnabled ? SnappieColor.labelDarkNormal : SnappieColor.labelPrimaryDisable
    }
    
    func fontStyle() -> SnappieFont.Style {
        return .proLabel1
    }
    
    func iconScale() -> IconScale {
        return size == .large ? .large : .small
    }
    
    private func iconSolidBackgroundColor(isPressed: Bool, isEnabled: Bool) -> Color {
        if !isEnabled { return Color.deepGreen600 }
        return isPressed ? SnappieColor.primaryNormal.opacity(0.5) : SnappieColor.primaryNormal
    }
}

// MARK: - Icon Background Button Styler
struct IconBackgroundStyler: ButtonStyler {
    let size: ButtonSizeType
    let isActive: Bool
    
    func height() -> CGFloat {
        size == .large
        ? ButtonSizeConstant.heightMedium
        : ButtonSizeConstant.heightSmall
    }
    
    func padding() -> EdgeInsets {
        return EdgeInsets(
            top: 8,
            leading: 8,
            bottom: 8,
            trailing: 8
        )
    }
    
    func background(isPressed: Bool, isEnabled: Bool) -> AnyView {
        let backgroundColor = iconBackgroundBackgroundColor(isPressed: isPressed, isEnabled: isEnabled)
        
        return AnyView(
            Circle()
                .fill(backgroundColor)
        )
    }
    
    func foregroundColor(isPressed: Bool, isEnabled: Bool) -> Color {
        guard isEnabled else { return Color.gray }
        return (isEnabled && isActive) ? SnappieColor.labelPrimaryNormal : SnappieColor.labelPrimaryDisable
    }
    
    func fontStyle() -> SnappieFont.Style {
        return .proLabel1
    }
    
    func iconScale() -> IconScale {
        return size == .large ? .large : .small
    }
    
    private func iconBackgroundBackgroundColor(isPressed: Bool, isEnabled: Bool) -> Color {
        if !isEnabled { return Color.deepGreen600 }
        return isPressed ? SnappieColor.containerFillNormal.opacity(0.5) : SnappieColor.containerFillNormal
    }
}

// MARK: - Icon With Text Button Styler
struct IconWithTextStyler: ButtonStyler {
    let isActive: Bool
    
    func height() -> CGFloat {
        ButtonSizeConstant.heightLarge
    }
    
    func padding() -> EdgeInsets {
        return EdgeInsets(
            top: 8,
            leading: 8,
            bottom: 8,
            trailing: 8
        )
    }
    
    func background(isPressed: Bool, isEnabled: Bool) -> AnyView {
        return AnyView(
            ZStack {
                if isPressed {
                    Circle()
                        .fill(SnappieColor.primaryNormal.opacity(0.1))
                        .frame(width: self.height(), height: self.height())
                }
                Circle()
                    .fill(SnappieColor.containerFillNormal)
                    .frame(width: self.height(), height: self.height())
            }
        )
    }
    
    func foregroundColor(isPressed: Bool, isEnabled: Bool) -> Color {
        guard isEnabled else { return Color.gray }
        return isActive ? SnappieColor.labelPrimaryActive : SnappieColor.labelDarkInactive
    }
    
    func fontStyle() -> SnappieFont.Style {
        return .kronaCaption1
    }
    
    func iconScale() -> IconScale {
        return .xlarge
    }
}
