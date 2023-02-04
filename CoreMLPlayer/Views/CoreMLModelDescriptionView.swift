//
//  CoreMLModelDescriptionView.swift
//  CoreML Player
//
//  Created by NA on 1/26/23.
//

import SwiftUI

struct CoreMLModelDescriptionView: View {
    @EnvironmentObject var coreMLModel: CoreMLModel
    
    var body: some View {
        VStack {
            ScrollView {
                ForEach(coreMLModel.modelDescription) { section in
                    Text(section.category).font(.headline)
                    VStack {
                        ForEach(section.items) { item in
                            HStack {
                                Text(item.key)
                                Spacer()
                                Text(item.value)
                            }
                        }
                    }
                    .padding()
                    .background(Color(red: 0, green: 0, blue: 0, opacity: 0.1))
                    .cornerRadius(10)
                }
            }
        }
        .maxFramed()
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                NavigationLink(destination: CoreMLModelView()) {
                    Image(systemName: "chevron.left.square")
                }
            }
        }
        .navigationTitle("\(coreMLModel.name ?? "") Model Description")
    }
}

struct CoreMLModelDescriptionView_Previews: PreviewProvider {
    static var previews: some View {
        CoreMLModelDescriptionView()
    }
}
