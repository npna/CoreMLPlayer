//
//  Stats.swift
//  CoreML Player
//
//  Created by NA on 1/24/23.
//

import Foundation

struct Stats: Identifiable {
    static var idCounter = 0
    
    let id: Int
    let key: String
    let value: String
    
    init(key: String, value: String) {
        id = Stats.idCounter
        self.key = key
        self.value = value
        
        Stats.idCounter += 1
    }
}
