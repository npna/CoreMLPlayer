//
//  Status.swift
//  CoreML Player
//
//  Created by NA on 1/23/23.
//

import SwiftUI

struct Status: View {
    let sfSymbol: (name: String, color: Color)
    let title: String
    let description: String?
    
    init(sfSymbol: (name: String, color: Color), title: String, description: String? = nil) {
        self.sfSymbol = sfSymbol
        self.title = title
        self.description = description
    }
    
    var body: some View {
        HStack {
            Image(systemName: sfSymbol.name)
                .resizable()
                .frame(width: 50, height: 50)
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(sfSymbol.color)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline)
                if let description {
                    Text(description).font(.caption)
                }
            }
        }
        .padding(.bottom)
    }
}

struct Status_Previews: PreviewProvider {
    static var previews: some View {
        Status(sfSymbol: ("x.square.fill", .brown), title: "Sample Title")
    }
}
