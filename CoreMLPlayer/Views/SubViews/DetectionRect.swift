//
//  DetectionRect.swift
//  CoreML Player
//
//  Created by NA on 2/2/23.
//

import SwiftUI

struct DetectionRect: View {
    @State private var isPresented = false
    @EnvironmentObject private var drawSettings: DrawSettings
    let obj: DetectedObject
    let drawingRect: CGRect
    
    var body: some View {
        Group {
            rectangle
            if drawSettings.labelEnabled {
                objectLabel(drawingRect: drawingRect, object: obj)
            }
        }
        .onTapGesture {
            isPresented = true
        }
    }
    
    var rectangle: some View {
        Rectangle()
            .stroke(drawSettings.borderColor, lineWidth: obj.isClassification ? 0 : drawSettings.borderWidth)
            .popover(isPresented: $isPresented) {
                DetectionDetailsPopover(obj: obj)
            }
            .background(obj.isClassification ? Color.clear : drawSettings.detectionBoxBackgroundColor)
            .frame(width: drawingRect.width, height: drawingRect.height)
            .offset(x: drawingRect.origin.x, y: drawingRect.origin.y)
    }
    
    func objectLabel(drawingRect: CGRect, object: DetectedObject) -> some View {
        ZStack {
            let labelExtraHeight = 3.0 // In addition to font size
            let label = drawSettings.confidenceDisplayed ? "\(object.label) (\(object.confidence))" : "\(object.label)"
            VStack(alignment: .leading) {
                Text(label)
                    .font(.system(size: drawSettings.labelFontSize))
                    .foregroundColor(drawSettings.labelTextColor)
                    .lineLimit(1)
                    .padding(.horizontal, 2)
                    .conditionalMofidier(object.isClassification, transform: { view in
                        view.padding(.all, 20)
                    })
                    .minimumScaleFactor(drawSettings.labelWrap ? drawSettings.labelMinFontScale : 1)
                    .frame(height: drawSettings.labelFontSize + labelExtraHeight)
                    .background(drawSettings.labelBackgroundColor)
            }
            .frame(width: drawSettings.labelWrap ? (drawingRect.width + drawSettings.borderWidth) : .none, height: drawingRect.height, alignment:.topLeading)
            .offset(x: drawingRect.origin.x - (drawSettings.borderWidth / 2), y: drawingRect.origin.y - (drawSettings.labelFontSize + (drawSettings.borderWidth / 2) + labelExtraHeight))
        }
    }
}
