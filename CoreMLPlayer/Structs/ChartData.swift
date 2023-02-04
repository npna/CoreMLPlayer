//
//  FPSChartData.swift
//  CoreML Player
//
//  Created by NA on 2/4/23.
//

import Foundation

struct FPSChartData: Identifiable {
    let name: String
    let time: String
    let value: Double
    let id = UUID()
}
