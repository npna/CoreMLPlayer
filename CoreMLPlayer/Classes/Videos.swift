//
//  Videos.swift
//  CoreML Player
//
//  Created by NA on 1/22/23.
//

import SwiftUI
import AVFoundation
import Vision

class Videos: Base, Gallery, ObservableObject {
    static let shared = Videos()
    
    @Published var files: [VideoFile] = []
    @Published var isLoading = false
    @Published var totalLoading: Double = 0
    @Published var alreadyLoaded: Double = 0
    
    func selectFiles() {
        guard let videos = super.selectFiles(contentTypes: K.Videos.contentTypes) else {
            super.showAlert(title: "Failed to import videos!")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            for video in videos {
                if !self.files.contains(where: { $0.url == video.standardizedFileURL }) {
                    let newVideo = VideoFile(name: video.lastPathComponent, type: video.pathExtension, url: video.standardizedFileURL)
                    self.setPreviewImage(video: newVideo)
                    DispatchQueue.main.async {
                        self.alreadyLoaded += 1
                        withAnimation {
                            self.files.append(newVideo)
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.alreadyLoaded = 0
                self.totalLoading = 0
            }
        }
    }
    
    func setPreviewImage(video: VideoFile) {
        let videoAsset = AVAsset(url: video.url)
        let generator = AVAssetImageGenerator(asset: videoAsset)
        let time = CMTime(value: 1, timescale: 1)
        
        generator.generateCGImageAsynchronously(for: time) { image, actualTime, error in
            if let img = image {
                let previewImage = NSImage(cgImage: img, size: CGSize(width: img.width, height: img.height))
                DispatchQueue.main.async {
                    for index in 0..<self.files.count {
                        if self.files[index].id == video.id {
                            self.files[index].previewImage = previewImage
                        }
                    }
                }
            }
        }
    }
}
