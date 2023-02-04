//
//  StatusProgressView.swift
//  CoreML Player
//
//  Created by NA on 1/23/23.
//

import SwiftUI

struct StatusProgressView: View {
    let title: String
    let description: String?
    
    init(title: String = "Please wait...", description: String? = nil) {
        self.title = title
        self.description = description
    }
    
    var body: some View {
        HStack {
            ProgressView().frame(width: 50, height: 50)
            VStack(alignment: .leading) {
                Text(title).font(.headline)
                if let description {
                    Text(description).font(.caption)
                }
            }
        }
    }
}

struct StatusProgressView_Previews: PreviewProvider {
    static var previews: some View {
        StatusProgressView()
    }
}
