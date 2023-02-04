//
//  LoadingGallery.swift
//  CoreML Player
//
//  Created by NA on 1/28/23.
//

import SwiftUI

struct LoadingGallery: View {
    @Environment(\.colorScheme) var colorScheme
    var alreadyLoaded: Double
    var totalLoading: Double
    
    var body: some View {
        VStack {
            Spacer()
            VStack {
                ProgressView(value: alreadyLoaded, total: totalLoading) {
                    if K.Images.generateThumbnail {
                        Text("Generating thumbnails...")
                    } else {
                        Text("Loading images...")
                    }
                }
                .padding()
            }
            .background(colorScheme == .light ? Color(red: 0.803, green: 0.808, blue: 0.821, opacity: 0.9) : Color(red: 0.084, green: 0.147, blue: 0.453, opacity: 0.9))
            .border(.gray)
        }
    }
}

struct LoadingGallery_Previews: PreviewProvider {
    static var previews: some View {
        LoadingGallery(alreadyLoaded: 10, totalLoading: 20)
    }
}
