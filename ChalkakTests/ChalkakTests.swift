//
//  ChalkakTests.swift
//  ChalkakTests
//
//  Created by 배현진 on 7/11/25.
//

import Testing
import Foundation
@testable import Chalkak

struct ChalkakTests {

    @Test func boundingBoxInfoPreservesNonSquareHeight() {
        let box = BoundingBoxInfo(
            origin: PointWrapper(CGPoint(x: 0.2, y: 0.1)),
            scale: 0.25,
            height: 0.75
        )

        #expect(box.cgRect == CGRect(x: 0.2, y: 0.1, width: 0.25, height: 0.75))
    }

    @Test func boundingBoxInfoFallsBackToScaleForLegacyBoxes() {
        let legacyBox = BoundingBoxInfo(
            origin: PointWrapper(CGPoint(x: 0.2, y: 0.1)),
            scale: 0.25
        )

        #expect(legacyBox.cgRect == CGRect(x: 0.2, y: 0.1, width: 0.25, height: 0.25))
    }

    @Test func compareUsesCenterSoSmallOriginJitterStillAligns() {
        let viewModel = BoundingBoxViewModel()
        viewModel.referenceBoundingBoxes = [
            CGRect(x: 0.20, y: 0.10, width: 0.25, height: 0.75)
        ]
        viewModel.liveBoundingBoxes = [
            CGRect(x: 0.145, y: 0.205, width: 0.36, height: 0.54)
        ]

        viewModel.compare()

        #expect(viewModel.isAligned)
    }

}
