//
//  ImageDetectionView.swift
//  CoreML Player
//
//  Created by NA on 1/23/23.
//

import SwiftUI
import Vision

struct ImageDetectionView: View {
    @EnvironmentObject private var coreMLModel: CoreMLModel
    @EnvironmentObject private var drawSettings: DrawSettings
    private let images = Images.shared
    @State private var currentImage: ImageFile? {
        didSet {
            hasNext = images.hasNext(currentImage)
            hasPrevious = images.hasPrevious(currentImage)
        }
    }
    @State private var hasPrevious: Bool = false
    @State private var hasNext: Bool = false
    
    @State private var detectedObjects: [DetectedObject] = []
    
    @GestureState private var scaleState: CGFloat = 1
    @GestureState private var offsetState = CGSize.zero
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1 {
        didSet {
            if scale < K.Zoom.min {
                scale = K.Zoom.min
            }
            if scale > K.Zoom.max {
                scale = K.Zoom.max
            }
        }
    }
    
    func resetScaleStatus(){
        offset = CGSize.zero
        scale = 1
    }
    
    private var initialImage: ImageFile?
    
    init(selectedImage: ImageFile) {
        initialImage = selectedImage
        resetScaleStatus()
    }
    
    var body: some View {
        Group {
            if let currentImage {
                showImage(currentImage)
            } else {
                Text("Image not found!")
            }
        }
        .navigationTitle(currentImage?.getTruncatedName() ?? "Image")
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                NavigationLink(destination: ImageGalleryView()) {
                    Image(systemName: "chevron.left.square")
                }
            }
        }
        .onAppear {
            setCurrentImage(initialImage)
            setObjectLocations()
        }
        .onDisappear {
            images.currentNSImage = nil
        }
    }
    
    @ViewBuilder
    func showImage(_ imageFile: ImageFile) -> some View {
        Group {
            if let nsImage = images.currentNSImage {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .overlay {
                        DetectionView(detectedObjects)
                    }
            } else {
                Text("Failed to load image!")
            }
        }
        .toolbar {
            toolbarButtons(imageFile: imageFile)
        }
        // SimultaneousGesture seems very buggy on macOS
        //.scaleEffect(scale * scaleState).offset(x: offset.width + offsetState.width, y: offset.height + offsetState.height).gesture(SimultaneousGesture(zoomGesture, dragGesture))
        // Defining 2 separate gestures acts a little better:
        .offset(x: offset.width + offsetState.width, y: offset.height + offsetState.height)
        .gesture(dragGesture)
        .scaleEffect(scale * scaleState)
        .gesture(zoomGesture)
    }
    
    func toolbarButtons(imageFile: ImageFile) -> some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Spacer()
            
            Button {
                drawSettings.presentPopover = true
            } label: {
                Label("DrawSettings", systemImage: "gearshape")
            }.popover(isPresented: $drawSettings.presentPopover) {
                DrawSettingsPopover()
            }
            
            Button {
                scale *= K.Zoom.buttonPlus
            } label: {
                Image(systemName: "plus.magnifyingglass").styledToolbarIcon()
            }
            .disabled(scale >= K.Zoom.max)
            .keyboardShortcut("=", modifiers: [])
            
            Button {
                scale *= K.Zoom.buttonMinus
            } label: {
                Image(systemName: "minus.magnifyingglass").styledToolbarIcon()
            }
            .disabled(scale <= K.Zoom.min)
            .keyboardShortcut("-", modifiers: [])
                        
            Button {
                resetScaleStatus()
            } label: {
                Image(systemName: "rectangle.center.inset.filled").styledToolbarIcon()
            }
            
            Button {
                if let previousImage = images.previousImage(currentImageFile: imageFile) {
                    detectedObjects = []
                    setCurrentImage(previousImage)
                    setObjectLocations()
                }
            } label: {
                Image(systemName: "arrow.left.square").styledToolbarIcon()
            }
            .disabled(!hasPrevious)
            .keyboardShortcut(.leftArrow, modifiers: [])
            
            Button {
                if let nextImage = images.nextImage(currentImageFile: imageFile) {
                    detectedObjects = []
                    setCurrentImage(nextImage)
                    setObjectLocations()
                }
            } label: {
                Image(systemName: "arrow.right.square").styledToolbarIcon()
            }
            .disabled(!hasNext)
            .keyboardShortcut(.rightArrow, modifiers: [])
        }
    }
    
    func setCurrentImage(_ image: ImageFile?) {
        if image == nil {
            currentImage = nil
            return
        }
        
        images.currentNSImage = image!.getNSImage()
        currentImage = image
    }
    
    func setObjectLocations() {
        detectedObjects = images.detectImageObjects(imageFile: currentImage, model: coreMLModel.model)
    }
    
    var zoomGesture: some Gesture {
        MagnificationGesture()
            .updating($scaleState) { currentState, gestureState, _ in
                gestureState = currentState
            }
            .onEnded { value in
                scale *= value
            }
    }

    var dragGesture: some Gesture {
        DragGesture()
            .updating($offsetState) { currentState, gestureState, _ in
                gestureState = currentState.translation
            }.onEnded { value in
                offset.height += value.translation.height
                offset.width += value.translation.width
            }
    }
}
