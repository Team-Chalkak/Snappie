//
//  Array + Ext.swift
//  Chalkak
//
//  Created by 배현진 on 7/16/25.
//

import SwiftUI

extension Array where Element == CGRect {
    /// 평균 CGRect 계산
    func average() -> CGRect? {
        guard !isEmpty else { return .zero }

        let sum = reduce(CGRect.zero) { partialResult, rect in
            CGRect(
                x: partialResult.origin.x + rect.origin.x,
                y: partialResult.origin.y + rect.origin.y,
                width: partialResult.size.width + rect.size.width,
                height: partialResult.size.height + rect.size.height
            )
        }

        let count = CGFloat(self.count)
        return CGRect(x: sum.origin.x / count,
                      y: sum.origin.y / count,
                      width: sum.size.width / count,
                      height: sum.size.height / count)
    }
}
