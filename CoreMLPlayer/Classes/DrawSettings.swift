//
//  DrawSettings.swift
//  CoreML Player
//
//  Created by NA on 1/27/23.
//

import SwiftUI

class DrawSettings: ObservableObject {
    @Published var presentPopover = false
    
    @AppStorage("DrawSettings-borderColor") var borderColor: Color = K.DrawDefaults.borderColor
    @AppStorage("DrawSettings-borderWidth") var borderWidth: Double = K.DrawDefaults.borderWidth
    
    @AppStorage("DrawSettings-labelEnabled") var labelEnabled: Bool = K.DrawDefaults.labelEnabled
    @AppStorage("DrawSettings-labelWrap") var labelWrap: Bool = K.DrawDefaults.labelWrap
    @AppStorage("DrawSettings-labelFontSize") var labelFontSize: Double = K.DrawDefaults.labelFontSize
    @AppStorage("DrawSettings-labelMinFontScale") var labelMinFontScale: Double = K.DrawDefaults.labelMinFontScale
    @AppStorage("DrawSettings-labelBackgroundColor") var labelBackgroundColor: Color = K.DrawDefaults.labelBackgroundColor
    @AppStorage("DrawSettings-labelTextColor") var labelTextColor: Color = K.DrawDefaults.labelTextColor
    
    @AppStorage("DrawSettings-confidenceDisplayed") var confidenceDisplayed: Bool = K.DrawDefaults.confidenceDisplayed
    @AppStorage("DrawSettings-confidenceFiltered") var confidenceFiltered: Bool = K.DrawDefaults.confidenceFiltered
    @AppStorage("DrawSettings-confidenceLimit") var confidenceLimit: Double = K.DrawDefaults.confidenceLimit
    
    @AppStorage("DrawSettings-detectionBoxBackgroundColor") var detectionBoxBackgroundColor: Color = K.DrawDefaults.detectionBoxBackgroundColor
    
    func resetSettings() {
        borderColor = K.DrawDefaults.borderColor
        borderWidth = K.DrawDefaults.borderWidth
            
        labelEnabled = K.DrawDefaults.labelEnabled
        labelWrap = K.DrawDefaults.labelWrap
        labelFontSize = K.DrawDefaults.labelFontSize
        labelMinFontScale = K.DrawDefaults.labelMinFontScale
        labelBackgroundColor = K.DrawDefaults.labelBackgroundColor
        labelTextColor = K.DrawDefaults.labelTextColor
        
        confidenceDisplayed = K.DrawDefaults.confidenceDisplayed
        confidenceFiltered = K.DrawDefaults.confidenceFiltered
        confidenceLimit = K.DrawDefaults.confidenceLimit
                
        detectionBoxBackgroundColor = K.DrawDefaults.detectionBoxBackgroundColor
    }
}

// Storing Color in AppStorage
extension Array: RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }
    
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

// It's not very accurate, but it's enough for our use case
extension Color: RawRepresentable {
    public init?(rawValue: String) {
        let c = rawValue.components(separatedBy: ",")
        if let r = Double(c[0]),
           let g = Double(c[1]),
           let b = Double(c[2]),
           let o = Double(c[3])
        {
            self = Color(.sRGB, red: r, green: g, blue: b, opacity: o)
        } else {
            self = Color.red
        }
    }
    
    public var rawValue: String {
        var red: CGFloat = 1,
            green: CGFloat = 0,
            blue: CGFloat = 0,
            alpha: CGFloat = 1
        
        NSColor(self).usingColorSpace(.sRGB)?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return "\(red),\(green),\(blue),\(alpha)"
    }
}
