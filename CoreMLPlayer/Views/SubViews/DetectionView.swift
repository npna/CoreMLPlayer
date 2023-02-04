//
//  DetectionView.swift
//  CoreML Player
//
//  Created by NA on 2/1/23.
//

import SwiftUI

struct DetectionView: View {
    @EnvironmentObject private var drawSettings: DrawSettings
    @State var selectedId: UUID?
    @State var otherLabels: [(label: String, confidence: String)] = []
    private var base = Base()
    let detectedObjects: [DetectedObject]
    var videoSize: CGSize?
    
    init(_ detectedObjects: [DetectedObject], videoSize: CGSize? = nil) {
        self.detectedObjects = detectedObjects
        if let videoWidth = videoSize?.width, videoWidth > 10 {
            self.videoSize = videoSize
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            if let videoSize, let videoRect = getVideoRect(geometrySize: geometry.size, videoSize: videoSize) {
                ZStack {
                    VStack { EmptyView() }
                        .frame(width: videoRect.width, height: videoRect.height)
                        .offset(x: videoRect.origin.x, y: videoRect.origin.y)
                        .overlay {
                            GeometryReader { videoGeometry in
                                forEachBB(detectedObjects: detectedObjects, geometry: videoGeometry)
                            }
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                forEachBB(detectedObjects: detectedObjects, geometry: geometry)
            }
        }
    }
    
    func getVideoRect(geometrySize: CGSize, videoSize: CGSize) -> CGRect {
        var offsetX = 0.0
        var offsetY = 0.0
        var width = geometrySize.width
        var height = geometrySize.height
        let cWidth = videoSize.width * (geometrySize.height / videoSize.height)
        let cHeight = videoSize.height * (geometrySize.width / videoSize.width)
        
        if cHeight < geometrySize.height {
            height = cHeight
            offsetY = (geometrySize.height - height) / 2
        } else {
            width = cWidth
            offsetX = (geometrySize.width - width) / 2
        }
        
        return CGRect(x: offsetX, y: offsetY, width: width, height: height)
    }
    
    func forEachBB(detectedObjects: [DetectedObject], geometry: GeometryProxy) -> some View {
        ForEach(detectedObjects) { obj in
            let confidence = Double(obj.confidence) ?? 0
            let drawingRect = base.prepareObjectForSwiftUI(object: obj, geometry: geometry)
            if drawSettings.confidenceFiltered && confidence < drawSettings.confidenceLimit {
                EmptyView()
            } else {
                DetectionRect(obj: obj, drawingRect: drawingRect)
            }
        }
    }
    
    func detectionDetailsIsPresented(object: DetectedObject) -> Binding<Bool> {
        return .init(get: {
            return self.selectedId == object.id
        }, set: { _ in    })
    }
}
