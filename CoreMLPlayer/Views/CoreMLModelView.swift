//
//  CoreMLModelView.swift
//  CoreML Player
//
//  Created by NA on 1/22/23.
//

import SwiftUI
import CoreML

struct CoreMLModelView: View {
    @EnvironmentObject var coreMLModel: CoreMLModel
    @State private var presentModelDetails = false
    @State private var isPresentingUnSelectConfirm = false
    
    var body: some View {
        VStack(alignment: .leading) {
            if coreMLModel.isLoading {
                loadingModel
            } else if coreMLModel.isValid {
                changeModel
            } else {
                selectModel
            }
        }
        .maxFramed()
    }
    
    var loadingModel: some View {
        StatusProgressView(title: "Please wait...", description: "Trying to compile and initialize your CoreML Model.")
    }
    
    @ViewBuilder
    var selectModel: some View {
        Status(sfSymbol: ("x.square.fill", .brown), title: "No Model Selected.", description: "Please select your CoreML Model to be able to use it on Images and Videos.")
        
        Button(action: coreMLModel.selectCoreMLModel) {
            Label("Select CoreML Model", systemImage: "m.square.fill")
        }.padding(.bottom, 25)
        
        // Included Models (if any)
        if K.CoreMLModel.builtInModels.count > 0 {
            Text("Or if you just want to try things out, select an included sample model below (source mentioned at the bottom):").font(.caption)
            ForEach(K.CoreMLModel.builtInModels, id: \.name) { model in
                Button {
                    coreMLModel.loadBuiltInModel(name: model.name)
                } label: {
                    Label("Try with \(model.name)", systemImage: "cube").font(.caption)
                }.buttonStyle(.link)
            }
            
            Spacer()
            ForEach(K.CoreMLModel.builtInModels, id: \.name) { model in
                if model.source.count > 0 {
                    Text("\(model.name) Original Source: \(model.source)").font(.footnote)
                }
            }
        }
    }
    
    @ViewBuilder
    var changeModel: some View {
        Status(sfSymbol: ("checkmark.square.fill", .green), title: coreMLModel.name ?? "", description: "CoreML Model has been loaded and compiled!")
        
        VStack {
            Picker("Reload Model on Next App Launch?", selection: coreMLModel.$autoloadSelection) {
                ForEach(CoreMLModel.AutoloadChoices.allCases) { choice in
                    if coreMLModel.selectedBuiltInModel == nil || choice != .recompile {
                        Text(choice.rawValue).tag(choice)
                    }
                }
            }
            .pickerStyle(.segmented)
            .padding(.vertical)
            .onChange(of: coreMLModel.autoloadSelection) { _ in
                coreMLModel.bookmarkModel()
            }
            
            Divider()
            
            Picker("Compute Units", selection: coreMLModel.$computeUnits) {
                Text("All").tag(MLComputeUnits.all)
                Text("CPU & Neural Engine").tag(MLComputeUnits.cpuAndNeuralEngine)
                Text("CPU & GPU").tag(MLComputeUnits.cpuAndGPU)
                Text("CPU").tag(MLComputeUnits.cpuOnly)
            }
            .pickerStyle(.segmented)
            .padding(.vertical)
            .onChange(of: coreMLModel.computeUnits) { _ in
                switch coreMLModel.computeUnits {
                case .cpuAndGPU, .all:
                    break
                default:
                    coreMLModel.gpuAllowLowPrecision = false
                }
                
                coreMLModel.reconfigure()
            }
            
            Divider()
            
            switch coreMLModel.computeUnits {
            case .cpuAndGPU, .all:
                Picker("Allow Low Precision Accumulation On GPU", selection: coreMLModel.$gpuAllowLowPrecision) {
                    Text("Yes").tag(true)
                    Text("No").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.top)
                .padding(.bottom, 30)
                .onChange(of: coreMLModel.gpuAllowLowPrecision) { _ in
                    coreMLModel.reconfigure()
                }
            default:
                EmptyView()
            }
            
            HStack {
                Button(action: coreMLModel.selectCoreMLModel) {
                    Label("Change CoreML Model", systemImage: "m.square.fill")
                }
                
                NavigationLink(destination: CoreMLModelDescriptionView()) {
                    Label("Model Description", systemImage: "info.square.fill")
                }
            }
            .padding(.top)
            
            Spacer()
            
            VStack {
                VStack(alignment: .leading) {
                    Text("Original Model:").font(.footnote).bold()
                    Text(getOriginalModel()).lineLimit(nil).minimumScaleFactor(0.8).font(.footnote).padding(.bottom)
                    
                    Text("Compiled Model:").font(.footnote).bold()
                    Button {
                        NSWorkspace.shared.selectFile(coreMLModel.getModelURLString().compiled.file, inFileViewerRootedAtPath: "")
                    } label: {
                        Text("\(coreMLModel.getModelURLString().compiled.file)").font(.footnote).foregroundColor(.brown)
                        if coreMLModel.selectedBuiltInModel == nil {
                            Text("(available until system reboot)").font(.footnote)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding()
            }
            .background(Color(red: 0, green: 0, blue: 0, opacity: 0.08))
            .cornerRadius(8)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(role: .destructive) {
                        isPresentingUnSelectConfirm = true
                    } label: {
                        Image(systemName: "x.square").styledToolbarIcon()
                    }
                    .confirmationDialog("Are you sure?", isPresented: $isPresentingUnSelectConfirm) {
                        Button("UnSelect Model", role: .destructive) {
                            coreMLModel.unSelectModel()
                        }
                    }
                    
                    Button {
                        presentModelDetails = true
                    } label: {
                        Image(systemName: "info.square").styledToolbarIcon()
                    }
                    .popover(isPresented: $presentModelDetails) {
                        CoreMLModelDescriptionView()
                            .frame(width: 500, height: 300)
                    }
                }
            }
        }
    }
    
    func getOriginalModel() -> String {
        var originalModel: String = ""
        if let builtIn = K.CoreMLModel.builtInModels.first(where: { $0.name == coreMLModel.selectedBuiltInModel })?.source {
            originalModel = "\(builtIn) - This sample model is included in CoreMLPlayer for demo purposes and to quickly try things out."
        } else {
            originalModel = coreMLModel.getModelURLString().original.file
        }
        
        return originalModel
    }
}

struct CoreMLModelView_Previews: PreviewProvider {
    static var previews: some View {
        CoreMLModelView()
    }
}
