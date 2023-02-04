//
//  Images.swift
//  CoreML Player
//
//  Created by NA on 1/22/23.
//

import Foundation
import AppKit
import CoreML
import Vision

struct ImageFile: File, Identifiable {
    static var idCounter = 0
    
    let id: Int
    let name: String
    let type: String
    let url: URL
    var thumbnail: NSImage?
    var nsImage: NSImage?
    
    init(name: String, type: String, url: URL) {
        id = ImageFile.idCounter
        self.name = name
        self.type = type
        self.url = url
        
        if K.Images.generateThumbnail {
            self.thumbnail = generateThumbnail()
        }
        
        switch K.Images.storeNSImagesInMemoryLimit {
            case .none:
                nsImage = nil
            case .limitedCount(let number):
                if ImageFile.idCounter < number {
                    nsImage = NSImage(contentsOf: url)
                }
            case .unlimited:
                nsImage = NSImage(contentsOf: url)
        }
        
        ImageFile.idCounter += 1
    }
    
    func getPreview() -> NSImage? {
        if thumbnail != nil {
            return thumbnail
        } else {
            return getNSImage()
        }
    }
    
    func getNSImage() -> NSImage? {
        if nsImage != nil {
            return nsImage
        } else {
            return NSImage(contentsOf: url)
        }
    }
    
    func generateThumbnail() -> NSImage? {
        guard let nsImage = getNSImage() else {
            return nil
        }
        
        let options = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: K.Images.thumbnailSize
        ] as CFDictionary

        guard let imageData = nsImage.tiffRepresentation,
              let imageSource = CGImageSourceCreateWithData(imageData as NSData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options)
        else {
            return nil
        }

        return NSImage(cgImage: image, size: CGSize(width: nsImage.actualSize.width, height: nsImage.actualSize.height))
    }
}

extension ImageFile: Equatable {
    static func ==(lhs: ImageFile, rhs: ImageFile) -> Bool {
        return lhs.id == rhs.id && lhs.url == rhs.url
    }
}
