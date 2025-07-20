//
//  UIImage + Ext.swift
//  Chalkak
//
//  Created by 배현진 on 7/19/25.
//

import UIKit

extension UIImage {
    func flippedHorizontally() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: size.width, y: 0)
        context.scaleBy(x: -1.0, y: 1.0)
        draw(at: .zero)
        let flippedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return flippedImage ?? self
    }
}
