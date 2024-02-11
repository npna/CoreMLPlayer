//
//  Constants.swift
//  CoreML Player
//
//  Created by NA on 1/22/23.
//

import SwiftUI
import UniformTypeIdentifiers

struct K {
    struct CoreMLModel {
        static let builtInModels: [(name: String, source: String)] = [ // name must match file name in app bundle
            (name: "YOLOv3Tiny", source: "https://github.com/pjreddie/darknet")
        ]
        static let contentTypes: [UTType] = [
            UTType(importedAs: "com.apple.coreml.model"),
            UTType(importedAs: "com.apple.coreml.mlpackage")
            ]
    }
    
    struct LazyVGrid {
        static let minSize: CGFloat = 120
        static let maxSize: CGFloat = 300
        static let frameWidth: CGFloat = 200
        static let frameHeight: CGFloat = 150
    }
    
    struct Images {
        static let contentTypes: [UTType] = [.image]
        static let generateThumbnail = true
        static let thumbnailSize = 200
        
        static let storeNSImagesInMemoryLimit: memoryStorage = .none
        static let forceNotUsingAsyncImage = false
    }
    
    struct Videos {
        static let contentTypes: [UTType] = [.movie]
    }
    
    struct Zoom {
        static let min: CGFloat = 0.4
        static let max: CGFloat = 25
        static let buttonPlus: CGFloat = 1.2
        static let buttonMinus: CGFloat = 0.8
    }
    
    struct DrawDefaults {
        static let borderColor: Color = .red
        static let borderWidth: Double = 2
        
        static let labelEnabled: Bool = true
        static let labelWrap: Bool = false
        static let labelBackgroundColor: Color = .red
        static let labelTextColor: Color = .white
        static let labelFontSize: Double = 13
        static let labelMinFontScale: Double = 0.4
        
        static let confidenceDisplayed: Bool = false
        static let confidenceFiltered: Bool = false
        static let confidenceLimit: Double = 0.5
        
        static let detectionBoxBackgroundColor: Color = .clear
    }
    
    enum memoryStorage {
        case none
        case limitedCount(n: Int)
        case unlimited
    }
}
