//
//  FPSChart.swift
//  CoreML Player
//
//  Created by NA on 2/4/23.
//

import SwiftUI

class FPSChart: ObservableObject {
    static let shared = FPSChart()
    
    @Published var data: [FPSChartData] = []
    
    func reset() {
        self.data.removeAll()
    }
}
