//
//  VideoDetection.swift
//  CoreML Player
//
//  Created by NA on 1/30/23.
//

import CoreML
import AVKit
import Vision
import Combine

class VideoDetection: Base, ObservableObject {
    @Published var playMode = PlayModes.normal {
        didSet {
            playing = false
        }
    }
    @Published var playing = false {
        didSet {
            playManager()
        }
    }
    @Published private(set) var frameObjects: [DetectedObject] = []
    @Published private(set) var videoInfo: (isPlayable: Bool, frameRate: Double, duration: CMTime, size: CGSize) = (false, 30, .zero, .zero)
    @Published private(set) var player: AVPlayer?
    @Published private(set) var canStart = false
    @Published private(set) var errorMessage: String?
    
    private var model: VNCoreMLModel?
    private var fpsCounter = 0
    private var fpsDisplay = 0
    private var chartDuration: Duration = .zero
    private var playerOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: nil)
    private var timeTracker = DispatchTime.now()
    private var lastDetectionTime: Double = 0
    private var videoHasEnded = false
    
    var videoURL: URL? {
        didSet {
            Task {
                await prepareToPlay(videoURL: videoURL)
            }
        }
    }
    
    private var avPlayerItemStatus: AVPlayerItem.Status = .unknown {
        didSet {
            if avPlayerItemStatus == .readyToPlay {
                canStart = true
                #if DEBUG
                print("PlayerItem is readyToPlay")
                #endif
            } else {
                canStart = false
            }
        }
    }
    
    private var avPlayerTimeControlStatus: AVPlayer.TimeControlStatus = .paused {
        didSet {
            if avPlayerTimeControlStatus != oldValue, playMode != .maxFPS {
                DispatchQueue.main.async {
                    switch self.avPlayerTimeControlStatus {
                    case .playing:
                        self.playing = true
                    default:
                        self.playing = false
                    }
                }
            }
        }
    }
    
    enum PlayModes {
        case maxFPS
        case normal
    }
    
    func disappearing() {
        playing = false
        frameObjects = []
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            DetectionStats.shared.items = []
        }
    }
    
    func setModel(_ vnModel: VNCoreMLModel?) {
        model = vnModel
    }
    
    func playManager() {
        if let playerItem = player?.currentItem, playerItem.currentTime() >= playerItem.duration {
            player?.seek(to: CMTime.zero)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.detectObjectsInFrame()
            }
            videoHasEnded = true
            frameObjects = []
        }
        
        if playing {
            if(videoHasEnded) {
                FPSChart.shared.reset()
            }
            videoHasEnded = false
            switch playMode {
            case .maxFPS:
                startMaxFPSDetection()
            default:
                startNormalDetection()
                player?.play()
            }
        } else {
            player?.pause()
        }
    }
    
    func seek(steps: Int) {
        guard let playerItem = player?.currentItem else {
            return
        }
        
        playerItem.step(byCount: steps)
        DispatchQueue.global(qos: .userInitiated).async {
            self.detectObjectsInFrame()
        }
    }
    
    func getRepeatInterval(_ reduceLastDetectionTime: Bool = true) -> Double {
        var interval = 0.0
        if videoInfo.frameRate > 0 {
            interval = (1 / videoInfo.frameRate)
        } else {
            interval = 30
        }
        
        if reduceLastDetectionTime {
            interval = max((interval - lastDetectionTime), 0.02)
        }
        return interval
    }
    
    func prepareToPlay(videoURL: URL?) async {
        guard let url = videoURL,
              url.isFileURL,
              let isReachable = try? url.checkResourceIsReachable(),
              isReachable
        else {
            return
        }
        
        let asset = AVAsset(url: url)
        
        do {
            if let videoTrack = try await asset.loadTracks(withMediaType: .video).first
            {
                let (frameRate, size) = try await videoTrack.load(.nominalFrameRate, .naturalSize)
                let (isPlayable, duration) = try await asset.load(.isPlayable, .duration)
                let playerItem = AVPlayerItem(asset: asset)
                playerItem.add(playerOutput)
                
                DispatchQueue.main.async {
                    self.videoInfo.frameRate = Double(frameRate)
                    self.videoInfo.duration = duration
                    self.videoInfo.size = size
                    if isPlayable {
                        self.player = AVPlayer(playerItem: playerItem)
                        self.videoInfo.isPlayable = true
                        
                        // Set avPlayerItemStatus when playerItem.status changes, when it is readyToPlay avPlayerItemStatus will set canStart to true
                        let playerItemStatusPublisher = playerItem.publisher(for: \.status)
                        let playerItemStatusSubscriber = Subscribers.Assign(object: self, keyPath: \.avPlayerItemStatus)
                        playerItemStatusPublisher.receive(subscriber: playerItemStatusSubscriber)
                        // AVPlayer.TimeControlStatus
                        let timeControlStatusPublisher = self.player?.publisher(for: \.timeControlStatus)
                        let timeControlStatusSubscriber = Subscribers.Assign(object: self, keyPath: \.avPlayerTimeControlStatus)
                        timeControlStatusPublisher?.receive(subscriber: timeControlStatusSubscriber)
                    } else {
                        self.errorMessage = "Video item is not playable."
                    }
                }
            }
        } catch {
            self.videoInfo.isPlayable = false
            self.errorMessage = "There was an error trying to load asset."
            #if DEBUG
            print("Error: \(error)")
            #endif
        }
    }
    
    func getPlayerItemIfContinuing(mode: PlayModes) -> AVPlayerItem? {
        guard let playerItem = player?.currentItem,
              playing == true,
              playMode == mode
        else {
            return nil
        }
        
        if playerItem.currentTime() >= playerItem.duration {
            DispatchQueue.main.async {
                self.playing = false
            }
            
            return nil
        }
        
        return playerItem
    }
        
    func startNormalDetection() {
        guard getPlayerItemIfContinuing(mode: .normal) != nil else {
            return
        }
        
        self.detectObjectsInFrame() {
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + self.getRepeatInterval()) { [weak self] in
                self?.startNormalDetection()
            }
        }
    }
    
    func startMaxFPSDetection() {
        guard let playerItem = getPlayerItemIfContinuing(mode: .maxFPS) else {
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            playerItem.step(byCount: 1)
            self?.detectObjectsInFrame() {
                self?.startMaxFPSDetection()
            }
        }
    }
    
    func detectObjectsInFrame(completion: (() -> ())? = nil) {
        guard let pixelBuffer = getPixelBuffer(), let model else { return }
        
        // Process the frame
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        let detectionResult = performObjectDetection(requestHandler: handler, vnModel: model)
        
        DispatchQueue.main.async {
            self.frameObjects = detectionResult.objects
            self.fpsCounter += 1
            let timePassed = DispatchTime.now().uptimeNanoseconds - self.timeTracker.uptimeNanoseconds
            if timePassed >= 1_000_000_000 {
                self.chartDuration += .seconds(1)
                if let detFPSDouble = Double(detectionResult.detectionFPS),
                   self.playMode == .maxFPS
                {
                    let narrowDuration = self.chartDuration.formatted(.units(allowed: [.seconds], width: .narrow))
                    FPSChart.shared.data.append(contentsOf: [
                        FPSChartData(name: "FPS", time: narrowDuration, value: Double(self.fpsCounter)),
                        FPSChartData(name: "Det. FPS", time: narrowDuration, value: detFPSDouble)
                    ])
                }
                self.timeTracker = DispatchTime.now()
                self.fpsDisplay = self.fpsCounter
                self.fpsCounter = 0
                #if DEBUG
                if self.playMode != .maxFPS {
                    print(self.fpsDisplay)
                }
                #endif
            }
            
            var stats: [Stats] = []
            
            if self.playMode == .maxFPS {
                stats.append(Stats(key: "FPS", value: "\(self.fpsDisplay)"))
                stats.append(Stats(key: "Det. FPS", value: "\(detectionResult.detectionFPS)"))
            }
            
            let detTime = Double(detectionResult.detectionTime.replacingOccurrences(of: " ms", with: "")) ?? 0
            self.lastDetectionTime = detTime / 1000
            
            stats += [
                Stats(key: "Det. Objects", value: "\(detectionResult.objects.count)"),
                Stats(key: "Det. Time", value: "\(detectionResult.detectionTime)"),
                Stats(key: "-", value: ""), // Divider
                Stats(key: "Width", value: "\(self.videoInfo.size.width)"),
                Stats(key: "Height", value: "\(self.videoInfo.size.height)")
            ]
            
            DetectionStats.shared.addMultiple(stats)
            
            if completion != nil {
                completion!()
            }
        }
    }
    
    func getUnixTimestampInt() -> Int {
        return Int(Date().timeIntervalSince1970)
    }
    
    func getPixelBuffer() -> CVPixelBuffer? {
        if let currentTime = player?.currentTime() {
            return playerOutput.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil)
        }
        
        return nil
    }
}

