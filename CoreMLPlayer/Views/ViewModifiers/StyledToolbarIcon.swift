//
//  StyledToolbarIcon.swift
//  CoreML Player
//
//  Created by NA on 1/23/23.
//

import SwiftUI

extension Image {
    func styledToolbarIcon(increaseBy: (width: CGFloat, height: CGFloat) = (0,0)) -> some View {
        let size: CGFloat = 20
        return self
            .resizable()
            .frame(width: size + increaseBy.width, height: size + increaseBy.height)
    }
}
