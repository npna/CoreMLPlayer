//
//  CoreMLPlayerApp.swift
//  CoreMLPlayer
//
//  Created by NA on 1/21/23.
//

import SwiftUI

@main
struct CoreMLPlayerApp: App {
    @StateObject private var coreMLModel = CoreMLModel()
    @StateObject private var drawSettings = DrawSettings()
    @StateObject private var detectionStats = DetectionStats.shared // updated from other classes
    
    var body: some Scene {
        Window("CoreML Player", id: "main") {
            MainView()
                .environmentObject(coreMLModel)
                .environmentObject(drawSettings)
                .environmentObject(detectionStats)
                .onAppear {
                    coreMLModel.autoload()
                }
                .frame(minWidth: 900, maxWidth: .infinity, minHeight: 530, maxHeight: .infinity, alignment: .center)
        }
    }
}
