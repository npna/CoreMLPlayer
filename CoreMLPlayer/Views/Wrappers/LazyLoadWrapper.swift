//
//  LazyLoadWrapper.swift
//  CoreML Player
//
//  Created by NA on 1/24/23.
//

import SwiftUI

struct LazyLoadWrapper<Content: View>: View {    
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}
