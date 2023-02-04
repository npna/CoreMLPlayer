//
//  ModelDescription.swift
//  CoreML Player
//
//  Created by NA on 1/26/23.
//

import Foundation

struct ModelDescription: Identifiable {
    let id = UUID()
    let category: String
    let items: [ModelDescription.Item]
    
    struct Item: Identifiable {
        let id = UUID()
        let key: String
        let value: String
    }
}
