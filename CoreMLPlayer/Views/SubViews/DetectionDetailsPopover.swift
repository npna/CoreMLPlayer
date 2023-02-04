//
//  DetectionDetailsPopover.swift
//  CoreML Player
//
//  Created by NA on 2/2/23.
//

import SwiftUI

struct DetectionDetailsPopover: View {
    let obj: DetectedObject
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Label").bold()
                    Text(obj.label)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Confidence").bold()
                    Text(obj.confidence)
                }
            }
            .padding(.bottom, 12)
            
            Text("Labels:")
            ScrollView {
                ForEach(obj.otherLabels, id: \.label) { ol in
                    HStack {
                        Text("\(ol.label)")
                        Spacer()
                        Text("\(ol.confidence)")
                    }
                    Divider()
                }
            }
            .frame(maxHeight: 300)
        }
        .padding()
    }
}
