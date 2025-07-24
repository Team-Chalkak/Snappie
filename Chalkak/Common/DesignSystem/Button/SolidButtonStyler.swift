//
//  SolidButtonStyler.swift
//  Chalkak
//
//  Created by 석민솔 on 7/24/25.
//

import SwiftUI

// MARK: - Solid Primary Button Styler
struct SolidPrimaryStyler: ButtonStyler {
    let size: ButtonSizeType
    
    func height() -> CGFloat {
        size == .large
        ? ButtonSizeConstant.heightLarge
        : ButtonSizeConstant.heightSmall
    }
    
    func padding() -> EdgeInsets {
        return size == .large
        ? EdgeInsets(
            top: 0,
            leading: 24,
            bottom: 0,
            trailing: 24
        )
        : EdgeInsets(
            top: 0,
            leading: 16,
            bottom: 0,
            trailing: 16
        )
    }
    
    func background(isPressed: Bool, isEnabled: Bool) -> AnyView {
        let cornerRadius: CGFloat = 999
        let backgroundColor = primaryBackgroundColor(isPressed: isPressed, isEnabled: isEnabled)
        
        return AnyView(
            ZStack {
                if isPressed {
                    SnappieColor.darkHeavy.opacity(0.2)
                        .mask(Capsule())
                }
                
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
            }
        )
    }
    
    func foregroundColor(isPressed: Bool, isEnabled: Bool) -> Color {
        guard isEnabled else { return Color.gray }
        
        return isEnabled
        ? SnappieColor.labelDarkNormal
        : SnappieColor.labelPrimaryDisable
    }
    
    func fontStyle() -> SnappieFont.Style {
        return size == .large ? .proLabel1 : .proLabel2
    }
    
    func iconScale() -> IconScale {
        return .large
    }
    
    private func primaryBackgroundColor(isPressed: Bool, isEnabled: Bool) -> Color {
        if !isEnabled { return Color.deepGreen600 }
        return isPressed ? SnappieColor.primaryNormal.opacity(0.5) : SnappieColor.primaryNormal
    }
}

// MARK: - Solid Secondary Button Styler
struct SolidSecondaryStyler: ButtonStyler {
    let size: ButtonSizeType
    let isOutlined: Bool
    let contentType: ButtonContentType
    
    func height() -> CGFloat {
        size == .large
        ? ButtonSizeConstant.heightLarge
        : ButtonSizeConstant.heightSmall
    }
    
    func padding() -> EdgeInsets {
        return size == .large
        ? EdgeInsets(
            top: 16,
            leading: 24,
            bottom: 16,
            trailing: 24
        )
        : EdgeInsets(
            top: 9,
            leading: 16,
            bottom: 9,
            trailing: 16
        )
    }
    
    func background(isPressed: Bool, isEnabled: Bool) -> AnyView {
        let cornerRadius: CGFloat = 999
        let backgroundColor = secondaryBackgroundColor(isPressed: isPressed, isEnabled: isEnabled)
        
        if isOutlined {
            let borderColor = Color.deepGreen500
            
            return AnyView(
                ZStack {
                    if isPressed {
                        SnappieColor.primaryNormal.opacity(0.1)
                            .mask(Capsule())
                    }
                    
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(borderColor, lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(backgroundColor)
                        )
                }
            )
        } else {
            return AnyView(
                ZStack {
                    if isPressed {
                        SnappieColor.primaryNormal.opacity(0.1)
                            .mask(Capsule())
                    }
                    
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(backgroundColor)
                }
            )
        }
    }
    
    func foregroundColor(isPressed: Bool, isEnabled: Bool) -> Color {
        guard isEnabled else { return Color.gray }
        return isEnabled ? SnappieColor.labelPrimaryNormal : SnappieColor.labelPrimaryDisable
    }
    
    func fontStyle() -> SnappieFont.Style {
        switch contentType {
        case .text:
            size == .large ? .proLabel1 : .proLabel2
        default: .proLabel1
        }
    }
    
    func iconScale() -> IconScale {
        switch contentType {
        case .icon:
            size == .large ? .xlarge : .large
        default: .large
        }
    }
    
    private func secondaryBackgroundColor(isPressed: Bool, isEnabled: Bool) -> Color {
        if !isEnabled { return Color.deepGreen600 }
        return isPressed ? SnappieColor.containerFillNormal.opacity(0.5) : SnappieColor.containerFillNormal
    }
}
