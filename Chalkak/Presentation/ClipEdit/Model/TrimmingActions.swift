//
//  TrimmingActions.swift
//  Chalkak
//
//  Created by bishoe01 on 1/12/26.
//

struct TrimmingActions {
    let pause: () -> Void
    let updateStart: (Double) -> Void
    let updateEnd: (Double) -> Void
    let seek: (Double) -> Void
    let shiftTrimmingRange: (Double) -> Void
    let updatePreviewImage: (Double) async -> Void
}
