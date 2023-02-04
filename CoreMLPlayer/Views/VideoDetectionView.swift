//
//  VideoDetectionView.swift
//  CoreML Player
//
//  Created by NA on 1/23/23.
//

import SwiftUI
import AVKit

struct VideoDetectionView: View {
    @EnvironmentObject private var coreMLModel: CoreMLModel
    @EnvironmentObject private var drawSettings: DrawSettings
    @StateObject private var videoDetection = VideoDetection()
    @State private var maxFPSMode = false
        
    var videoEnded = NotificationCenter.default.publisher(for: NSNotification.Name.AVPlayerItemDidPlayToEndTime)
    
    let videoFile: VideoFile
    
    var body: some View {
        VStack {
            if let error = videoDetection.errorMessage {
                Text(error)
            } else if videoDetection.playMode == .normal {
                videoPlayer()
            } else if videoDetection.playMode == .maxFPS {
                videoPlayer(hideControls: true)
            } else {
                Text("Could not load frame!")
            }
        }
        .onAppear {
            videoDetection.setModel(coreMLModel.model)
            videoDetection.videoURL = videoFile.url
        }
        .onDisappear {
            videoDetection.disappearing()
            FPSChart.shared.reset()
        }
        .onReceive(videoEnded) { _ in
            videoDetection.playing = false
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                NavigationLink(destination: VideoGalleryView()) {
                    Image(systemName: "chevron.left.square")
                }
            }
            
            ToolbarItemGroup(placement: .secondaryAction) {
                Button {
                    videoDetection.seek(steps: -1)
                } label: {
                    Image(systemName: "chevron.backward")
                }
                .keyboardShortcut(.leftArrow, modifiers: [])
                .disabled(videoDetection.playing)
                
                Button {
                    videoDetection.playing.toggle()
                } label: {
                    Image(systemName: videoDetection.playing ? "pause.fill" : "play.fill").styledToolbarIcon()
                }
                .keyboardShortcut(.space, modifiers: [])
                
                Button {
                    videoDetection.seek(steps: 1)
                } label: {
                    Image(systemName: "chevron.forward")
                }
                .keyboardShortcut(.rightArrow, modifiers: [])
                .disabled(videoDetection.playing)
                
                Spacer()
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Spacer()
                
                HStack {
                    Text("FPS Mode")
                    Toggle("", isOn: $maxFPSMode)
                        .toggleStyle(.switch)
                        .onChange(of: maxFPSMode) { enabled in
                            if enabled {
                                videoDetection.playMode = .maxFPS
                            } else {
                                videoDetection.playMode = .normal
                            }
                        }
                }
                
                Button {
                    drawSettings.presentPopover = true
                } label: {
                    Label("DrawSettings", systemImage: "gearshape")
                }.popover(isPresented: $drawSettings.presentPopover) {
                    DrawSettingsPopover()
                }
            }
        }
        .navigationTitle(videoFile.getTruncatedName())
    }
    
    @ViewBuilder
    func videoPlayer(hideControls: Bool = false) -> some View {
        Group {
            if hideControls, let player = videoDetection.player {
                AVPlayerWithoutControls(player: player)
            } else {
                VideoPlayer(player: videoDetection.player)
            }
        }
        .overlay {
            DetectionView(videoDetection.frameObjects, videoSize: videoDetection.videoInfo.size)
        }
    }
}

struct AVPlayerWithoutControls: NSViewRepresentable {
    var player : AVPlayer
    
    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .none
        view.player = player
        return view
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) { }
}
