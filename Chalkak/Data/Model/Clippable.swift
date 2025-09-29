//
//  Clippable.swift
//  Chalkak
//
//  Created by 석민솔 on 9/15/25.
//

import Foundation

protocol Clippable {
    var id: String { get }
    var url: URL { get }
    var originalDuration: Double { get }
    
    // 트리밍 범위
    var startPoint: Double { get set }
    var endPoint: Double { get set }
}
