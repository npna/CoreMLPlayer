//
//  Separated.swift
//  CoreML Player
//
//  Created by NA on 2/3/23.
//

import SwiftUI

struct Separated: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(.top)
        Divider().padding(.horizontal)
    }
}

extension View {
    func separated() -> some View {
        self.modifier(Separated())
    }
}
