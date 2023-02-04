//
//  Images.swift
//  CoreML Player
//
//  Created by NA on 1/22/23.
//

import SwiftUI
import CoreML
import Vision

class Images: Base, Gallery, ObservableObject {
    @Published var files: [ImageFile] = [] {
        didSet {
            if files.count == 0 {
                ImageFile.idCounter = 0
            }
        }
    }
    @Published var isLoading: Bool = false
    @Published var totalLoading: Double = 0
    @Published var alreadyLoaded: Double = 0
    var currentNSImage: NSImage? = nil {
        didSet {
            if currentNSImage == nil {
                DetectionStats.shared.items = []
            }
        }
    }
    
    static let shared = Images()
    
    func selectFiles() {
        guard let images = super.selectFiles(contentTypes: K.Images.contentTypes) else {
            super.showAlert(title: "Failed to import images!")
            return
        }
        
        if galleryUsingAsyncImage() {
            for image in images {
                if !self.files.contains(where: { $0.url == image.standardizedFileURL }) {
                    let newImage = ImageFile(name: image.lastPathComponent, type: image.pathExtension, url: image.standardizedFileURL)
                    files.append(newImage)
                }
            }
        } else {
            isLoading = true
            totalLoading = Double(images.count)
            
            DispatchQueue.global(qos: .userInitiated).async {
                for image in images {
                    if !self.files.contains(where: { $0.url == image.standardizedFileURL }) {
                        let newImage = ImageFile(name: image.lastPathComponent, type: image.pathExtension, url: image.standardizedFileURL)
                        DispatchQueue.main.async {
                            self.alreadyLoaded += 1
                            withAnimation {
                                self.files.append(newImage)
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
    }
    
    func detectImageObjects(imageFile: ImageFile?, model: VNCoreMLModel?) -> [DetectedObject] {
        let (detectedObjects, detectionTime, _) = super.detectImageObjects(image: imageFile, model: model)
        
        DetectionStats.shared.addMultiple([
            Stats(key: "Det. Objects", value: "\(detectedObjects.count)"),
            Stats(key: "Time", value: "\(detectionTime)"),
            Stats(key: "-", value: ""), // Divider
            Stats(key: "Width", value: "\(currentNSImageDetails().width)"),
            Stats(key: "Height", value: "\(currentNSImageDetails().height)")
        ])
        
        return detectedObjects
    }
    
    func currentNSImageDetails() -> (width: String, height: String) {
        guard let nsImage = currentNSImage else {
            return (width: "0", height: "0")
        }
        
        let imageWidth = String(format: "%.0f", nsImage.actualSize.width)
        let imageHeight = String(format: "%.0f", nsImage.actualSize.height)
        return (width: imageWidth, height: imageHeight)
    }
    
    func galleryUsingAsyncImage() -> Bool {
        if K.Images.forceNotUsingAsyncImage {
            return false
        }
        
        if K.Images.generateThumbnail == true {
            return false
        }
        
        switch K.Images.storeNSImagesInMemoryLimit {
            case .none:
                return true
            case .unlimited:
                return false
            case .limitedCount(let number):
                if files.count > number {
                    return true
                } else {
                    return false
                }
        }
    }
    
    func currentImage(id: ImageFile.ID) -> ImageFile? {
        files.first { $0.id == id }
    }
    
    func nextImage(currentImageFile: ImageFile) -> ImageFile? {
        files.first { $0.id == (currentImageFile.id + 1) }
    }
    
    func previousImage(currentImageFile: ImageFile) -> ImageFile? {
        files.first { $0.id == (currentImageFile.id - 1) }
    }
    
    func hasNext(_ imageFile: ImageFile?) -> Bool {
        if let image = imageFile {
            return (image.id + 1) < files.count
        }
        return false
    }
    
    func hasPrevious(_ imageFile: ImageFile?) -> Bool {
        if let image = imageFile {
            return image.id > 0
        }
        return false
    }
}
