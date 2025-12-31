//
//  TimeInterval+Extension.swift
//  Chalkak
//
//  Created by bishoe01 on 12/27/25.
//

import Foundation

extension TimeInterval {
    var formattedTime: String {
        guard !self.isNaN && !self.isInfinite else { return "00:00" }
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}
