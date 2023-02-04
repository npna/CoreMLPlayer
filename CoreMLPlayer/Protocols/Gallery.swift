//
//  Gallery.swift
//  CoreML Player
//
//  Created by NA on 1/28/23.
//

import Foundation

protocol Gallery: ObservableObject {
    associatedtype GalleryFile: File
    
    var files: [GalleryFile] { get set }
    func selectFiles()
}
