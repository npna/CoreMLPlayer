//
//  DrawSettingsPopover.swift
//  CoreML Player
//
//  Created by NA on 1/27/23.
//

import SwiftUI

struct DrawSettingsPopover: View {
    @EnvironmentObject private var drawSettings: DrawSettings
    @State private var presentConfidencePopover = false
    @SceneStorage("SelectedDrawSettingsTab") private var tabSelection = 0
    
    var body: some View {
        VStack {
            TabView(selection: $tabSelection) {
                VStack {
                    Section { confidenceSettings } header: {
                        HStack {
                            Image(systemName: "percent")
                            Text("Confidence Settings").bold()
                        }
                        .separated()
                    }
                }
                .tabItem {
                    Text("Confidence")
                }
                .tag(0)
                
                VStack {
                    Section { labelSettings } header: {
                        HStack {
                            Image(systemName: "character.textbox")
                            Text("Label Settings").bold()
                        }
                        .separated()
                    }
                    
                    if drawSettings.labelEnabled {
                        Section { labelFontSettings } header: {
                            HStack {
                                Image(systemName: "a.magnify")
                                Text("Label Font").bold()
                            }
                            .separated()
                        }
                    }
                }
                .tabItem {
                    Text("Labels")
                }
                .tag(1)
                
                VStack {
                    Section { borderSettings } header: {
                        HStack {
                            Image(systemName: "text.line.last.and.arrowtriangle.forward")
                            Text("Border").bold()
                        }
                        .separated()
                    }
                    
                    Section { detectionBoxSettings } header: {
                        HStack {
                            Image(systemName: "rectangle.inset.filled")
                            Text("Background").bold()
                        }
                        .separated()
                    }
                }
                .tabItem {
                    Text("Detection Box")
                }
                .tag(2)
            }
            
            Button {
                drawSettings.resetSettings()
            } label: {
                Text("Reset to defaults")
            }
            .padding(.top)
        }
        .padding()
        .frame(minWidth: 350, maxWidth: 500, alignment: .topLeading)
    }
    
    @ViewBuilder
    var labelSettings: some View {
        VStack {
            HStack {
                Text("Enable")
                Spacer()
                Toggle("", isOn: $drawSettings.labelEnabled) // no .animation(), it looks so weird...
                    .toggleStyle(.switch)
            }
            
            if drawSettings.labelEnabled {
                HStack {
                    Text("Wrap")
                    Spacer()
                    Toggle("", isOn: $drawSettings.labelWrap)
                        .toggleStyle(.switch)
                }
                
                HStack {
                    Text("Text Color")
                    Spacer()
                    ColorPicker("", selection: $drawSettings.labelTextColor)
                }
                
                HStack {
                    Text("Background")
                    Spacer()
                    ColorPicker("", selection: $drawSettings.labelBackgroundColor)
                }
            }
        }
        .padding()
        if !drawSettings.labelEnabled {
            Spacer()
        }
    }
    
    @ViewBuilder
    var labelFontSettings: some View {
        VStack {
            HStack {
                Text("Size")
                Spacer()
                Slider(value: $drawSettings.labelFontSize,
                       in: 6...20,
                       step: 1,
                       minimumValueLabel: Text("6"),
                       maximumValueLabel: Text("20"),
                       label: {}
                )
            }
            
            if drawSettings.labelWrap {
                HStack {
                    Text("Min. Scale")
                    Spacer()
                    Slider(value: $drawSettings.labelMinFontScale,
                           in: 0.2...1.0,
                           step: 0.1,
                           minimumValueLabel: Text("0.2"),
                           maximumValueLabel: Text("1.0"),
                           label: {}
                    )
                }
            }
        }
        .padding()
        Spacer()
    }
    
    @ViewBuilder
    var confidenceSettings: some View {
        VStack {
            HStack {
                Text("Display Value")
                Spacer()
                Toggle("", isOn: $drawSettings.confidenceDisplayed)
                    .toggleStyle(.switch)
            }
            HStack {
                Text("Filter")
                Spacer()
                Toggle("", isOn: $drawSettings.confidenceFiltered)
                    .toggleStyle(.switch)
            }
            if drawSettings.confidenceFiltered {
                HStack {
                    Text("Min. Confidence")
                    Spacer()
                    Slider(value: $drawSettings.confidenceLimit,
                           in: 0.0...1.0,
                           minimumValueLabel: Text("0"),
                           maximumValueLabel: Text("1"),
                           label: {}
                    )
                    .onChange(of: drawSettings.confidenceLimit) { _ in
                        presentConfidencePopover = true
                    }
                    .popover(isPresented: $presentConfidencePopover) {
                        VStack {
                            let confidenceLimit = String(format: "%.3f", drawSettings.confidenceLimit)
                            Text(confidenceLimit)
                        }
                        .frame(width: 60, height: 22)
                    }
                }
            }
        }
        .padding()
        Spacer()
    }
    
    var borderSettings: some View {
        VStack {
            HStack {
                Text("Width")
                Spacer()
                Slider(value: $drawSettings.borderWidth,
                       in: 0...10,
                       step: 1,
                       minimumValueLabel: Text("0"),
                       maximumValueLabel: Text("10"),
                       label: {}
                )
            }
            
            HStack {
                Text("Color")
                Spacer()
                ColorPicker("", selection: $drawSettings.borderColor)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    var detectionBoxSettings: some View {
        VStack {
            HStack {
                Text("Background")
                Spacer()
                ColorPicker("", selection: $drawSettings.detectionBoxBackgroundColor)
            }
        }
        .padding()
        Spacer()
    }
}

struct DrawSettings_Previews: PreviewProvider {
    static var previews: some View {
        DrawSettingsPopover()
    }
}
