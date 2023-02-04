//
//  ConditionalModifier.swift
//  CoreML Player
//
//  Created by NA on 1/23/23.
//

import SwiftUI

extension View {
    @ViewBuilder
    func conditionalMofidier<Content: View>(_ condition: @autoclosure () -> Bool, transform: (Self) -> Content) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }
}
