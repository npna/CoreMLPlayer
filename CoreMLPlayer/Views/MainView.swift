//
//  MainView.swift
//  CoreMLPlayer
//
//  Created by NA on 1/21/23.
//

import SwiftUI
import Charts

struct MainView: View {
    @EnvironmentObject private var coreMLModel: CoreMLModel
    @EnvironmentObject private var detectionStats: DetectionStats
    
    var body: some View {
        NavigationSplitView {
            List {
                Section("CoreML Model") {
                    NavigationLink { CoreMLModelView() } label: { Label(coreMLModel.name ?? "Select Model", systemImage: "m.square.fill") }
                }
                .collapsible(false)
                
                if coreMLModel.isValid {
                    Section("Try the model on") {
                        NavigationLink { VideoGalleryView() } label: { Label("Videos", systemImage: "video") }
                        NavigationLink { ImageGalleryView() } label: { Label("Images", systemImage: "photo") }
                    }
                    .collapsible(false)
                }
            }
            .navigationSplitViewColumnWidth(min: 210, ideal: 230, max: 300)
            
            if detectionStats.show {
                let chartData = FPSChart.shared.data
                if chartData.count > 0 {
                    VStack {
                        Chart(chartData) {
                            LineMark(
                                x: .value("Time Passed", $0.time),
                                y: .value("FPS", $0.value)
                            )
                            .foregroundStyle(by: .value("", $0.name))
                        }
                        .chartXAxis(Visibility.hidden)
                        .animation(.easeInOut, value: chartData.count)
                    }
                    .padding()
                }
                
                Spacer()
                VStack {
                    VStack(spacing: 4) {
                        ForEach(detectionStats.items) { item in
                            if item.key == "-" && item.value == "" {
                                Divider().padding(.vertical)
                            } else {
                                HStack {
                                    Text(item.key).bold()
                                    Spacer()
                                    Text(item.value)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.08))
                .cornerRadius(5)
                .padding()
            }
            
        } detail: {
            VStack(spacing: 25) {
                Image("CoreMLPlayerLogo")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .rotation3DEffect(.degrees(-15), axis: (x: 0, y: 1, z: 0.1))
                Text("Welcome to CoreML Player!")
                    .font(.headline)
            }
            .padding(.bottom)
            
            VStack {
                Text("Apply your CoreML Model to different images and videos while being able to filter by confidence rate or zoom in for a better inspection.")
                    .multilineTextAlignment(.center)
                Link("Project's Github", destination: URL(string: "https://github.com/npna/CoreMLPlayer")!)
            }
            .frame(maxWidth: 400)
            .font(.caption)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
