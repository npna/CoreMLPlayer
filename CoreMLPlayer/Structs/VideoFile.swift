//
//  Video.swift
//  CoreML Player
//
//  Created by NA on 1/22/23.
//

import Foundation
import AppKit
import AVFoundation

struct VideoFile: File, Identifiable {
    static var idCounter = 0
    
    let id: Int
    let name: String
    let type: String
    let url: URL
    var previewImage: NSImage? = nil
    
    init(name: String, type: String, url: URL) {
        self.id = VideoFile.idCounter
        self.name = name
        self.type = type
        self.url = url
        
        VideoFile.idCounter += 1
    }
}
