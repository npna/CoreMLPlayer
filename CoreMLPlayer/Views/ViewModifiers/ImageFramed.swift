//
//  ImageFramed.swift
//  CoreML Player
//
//  Created by NA on 1/23/23.
//

import SwiftUI

extension Image {
    func imageFramed() -> some View {
        self
            .resizable()
            .border(.black, width: 5)
            .cornerRadius(8)
            .aspectRatio(contentMode: .fit)
    }
}
