//
//  VideoGalleryView.swift
//  CoreMLPlayer
//
//  Created by NA on 1/21/23.
//

import SwiftUI

struct VideoGalleryView: View {
    @StateObject private var videos = Videos.shared
    
    var body: some View {
        VStack(alignment: .leading) {
            if videos.files.count > 0 {
                ZStack {
                    videoGrid
                    if videos.isLoading {
                        LoadingGallery(alreadyLoaded: videos.alreadyLoaded, totalLoading: videos.totalLoading)
                    }
                }
            } else {
                addVideos
            }
        }
        .maxFramed()
    }
    
    @ViewBuilder
    var addVideos: some View {
        Status(sfSymbol: ("x.square.fill", .brown), title: "No Videos Found.", description: "Please add videos to apply your MLModel.")
        
        Button(action: videos.selectFiles) {
            Label("Add Videos", systemImage: "video")
        }
    }
    
    @ViewBuilder
    var videoGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: K.LazyVGrid.minSize, maximum: K.LazyVGrid.maxSize))]) {
                ForEach(videos.files) { video in
                    Group {
                        if let imagePreview = video.previewImage {
                            NavigationLink {
                                VideoDetectionView(videoFile: video)
                            } label: {
                                VStack {
                                    Image(nsImage: imagePreview).imageFramed()
                                    Text(video.name).font(.caption).lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                        } else {
                            Color.red
                        }
                    }
                    .frame(maxWidth: K.LazyVGrid.frameWidth, maxHeight: K.LazyVGrid.frameHeight)
                }
            }.padding()
        }
        .toolbar {
            GalleryToolbar(gallery: videos)
        }
    }
}

struct VideoGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        VideoGalleryView()
    }
}
