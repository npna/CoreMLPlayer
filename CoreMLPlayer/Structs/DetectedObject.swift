//
//  DetectedObject.swift
//  CoreML Player
//
//  Created by NA on 1/26/23.
//

import Foundation

struct DetectedObject: Identifiable {
    let id: UUID
    let label: String
    let confidence: String
    let otherLabels: [(label: String, confidence: String)]
    let width: CGFloat
    let height: CGFloat
    let x: CGFloat
    let y: CGFloat
    var isClassification: Bool = false
}
