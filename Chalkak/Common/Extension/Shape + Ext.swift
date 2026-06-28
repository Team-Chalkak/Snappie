//
//  Shape + Ext.swift
//  Chalkak
//
//  Created by 배현진 on 6/28/26.
//

import SwiftUI

struct TooltipTriangleShape: Shape {
    func path(in rect: CGRect) -> SwiftUI.Path {
        var path = SwiftUI.Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
