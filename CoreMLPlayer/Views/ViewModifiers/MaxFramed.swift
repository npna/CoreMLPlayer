//
//  MaxFramed.swift
//  CoreML Player
//
//  Created by NA on 1/23/23.
//

import SwiftUI

struct MaxFramed: ViewModifier {
    func body(content: Content) -> some View {
        content.frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.topLeading)
    }
}

extension View {
    func maxFramed(withPadding: Bool = true) -> some View {
        self
            .modifier(MaxFramed())
            .conditionalMofidier(withPadding) { view in
                view.padding()
            }
    }
}
