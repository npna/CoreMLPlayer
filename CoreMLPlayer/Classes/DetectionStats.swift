//
//  DetectionStats.swift
//  CoreML Player
//
//  Created by NA on 1/24/23.
//

import Foundation

class DetectionStats: ObservableObject {
    static let shared = DetectionStats()
    @Published var show: Bool = false
    @Published var items: [Stats] = [] {
        didSet {
            if items.count > 0 {
                show = true
            } else {
                show = false
            }
        }
    }
    
    func addMultiple(_ stats: [Stats], removeAllFirst: Bool = true) {
        if removeAllFirst {
            items.removeAll()
        }
        
        for item in stats {
            items.append(item)
        }
    }
}
