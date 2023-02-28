//
//  File.swift
//  CoreML Player
//
//  Created by NA on 1/28/23.
//

import Foundation

protocol File {
    associatedtype ID: Hashable
    var id: ID { get }
    var name: String { get }
    var type: String { get }
    var url: URL { get }
}

extension File {
    func getTruncatedName(limit: Int = 20, truncateWith: String = "...") -> String {
        guard name.count > limit, (name.count - truncateWith.count) > 0 else { return name }
        let headCount = Int(ceil(Float(limit - truncateWith.count) / 2.0))
        let tailCount = Int(floor(Float(limit - truncateWith.count) / 2.0))
        
        return "\(name.prefix(headCount))\(truncateWith)\(name.suffix(tailCount))"
    }
}
