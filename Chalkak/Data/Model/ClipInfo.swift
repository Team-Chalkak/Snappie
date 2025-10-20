//
//  ClipInfo.swift
//  Chalkak
//
//  Created by 석민솔 on 9/16/25.
//

import Foundation

protocol ClipInfo {
    var videoURL: URL { get }
    var startPoint: Double { get }
    var endPoint: Double { get }
}
