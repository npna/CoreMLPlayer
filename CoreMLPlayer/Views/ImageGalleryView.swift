//
//  ImageGalleryView.swift
//  CoreMLPlayer
//
//  Created by NA on 1/21/23.
//

import SwiftUI

struct ImageGalleryView: View {
    @StateObject private var images = Images.shared
    
    var body: some View {
        VStack(alignment: .leading) {
            if images.files.count > 0 {
                ZStack {
                    imageGrid
                    if images.isLoading {
                        LoadingGallery(alreadyLoaded: images.alreadyLoaded, totalLoading: images.totalLoading)
                    }
                }
            } else {
                addImages
            }
        }
        .maxFramed()
    }
    
    @ViewBuilder
    var addImages: some View {
        Status(sfSymbol: ("x.square.fill", .brown), title: "No Images Found.", description: "Please add images to apply your MLModel.")
        
        Button(action: images.selectFiles) {
            Label("Add Images", systemImage: "photo")
        }
    }
    
    var imageGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: K.LazyVGrid.minSize, maximum: K.LazyVGrid.maxSize))]) {
                ForEach(images.files) { image in
                    imageView(image: image)
                }
            }.padding()
        }
        .toolbar {
            GalleryToolbar(gallery: images)
        }
    }
    
    
    func imageView(image: ImageFile) -> some View {
        Group {
            if images.galleryUsingAsyncImage() {
                AsyncImage(url: image.url, transaction: .init(animation: .easeInOut)) { phase in
                    if let imagePreview = phase.image {
                        NavigationLink {
                            LazyLoadWrapper(ImageDetectionView(selectedImage: image))
                        } label: {
                            VStack {
                                imagePreview.imageFramed()
                                Text(image.getTruncatedName()).font(.caption).lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    } else if phase.error != nil {
                        Color.red
                    } else {
                        ProgressView()
                    }
                }
            } else {
                NavigationLink {
                    withAnimation {
                        LazyLoadWrapper(ImageDetectionView(selectedImage: image))
                    }
                } label: {
                    if let nsImage = image.getPreview() {
                        VStack {
                            Image(nsImage: nsImage).imageFramed()
                            Text(image.getTruncatedName()).font(.caption).lineLimit(1)
                        }
                    } else {
                        Color.red
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: K.LazyVGrid.frameWidth, maxHeight: K.LazyVGrid.frameHeight)
    }
}

struct ImageGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        ImageGalleryView()
    }
}
