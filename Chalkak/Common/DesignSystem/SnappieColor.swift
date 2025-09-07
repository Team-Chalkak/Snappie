//
//  SnappieColor.swift
//  Chalkak
//
//  Created by 석민솔 on 7/21/25.
//

import SwiftUI

/**
 프로젝트에서 사용할 컬러 시스템

 ## 사용방법
 ```swift
 Text("Primary Light Label")
     .foregroundColor(SnappieColor.labelPrimaryNormal)
 ```
 */
enum SnappieColor {
    static let darkLight: Color = Color("deep-green-200")
    static let darkNormal: Color = Color("deep-green-400")
    static let darkStrong: Color = Color("deep-green-600")
    static let darkHeavy: Color = Color("deep-green-700")
    static let primaryLight: Color = Color("matcha-100")
    static let primaryNormal: Color = Color("matcha-500")
    static let primaryStrong: Color = Color("matcha-600")
    static let primaryHeavy: Color = Color("matcha-700")
    
    static let labelPrimaryNormal: Color = SnappieColor.primaryLight
    static let labelPrimaryActive: Color = SnappieColor.primaryNormal
    static let labelPrimaryDisable: Color = SnappieColor.darkNormal
    static let labelDarkNormal: Color = SnappieColor.darkStrong
    static let labelDarkInactive: Color = SnappieColor.darkLight
    
    static let containerFillNormal: Color = SnappieColor.darkStrong
    static let redRecording: Color = Color("red-recording")
    static let gradientFillNormal = Gradient(colors: [ Color("matcha-200").opacity(0.2), Color("deep-green-600").opacity(0.15)])
    static var overlayStroke: CGColor? {
        return UIColor(named: "matcha-100")?.cgColor
    }
}
