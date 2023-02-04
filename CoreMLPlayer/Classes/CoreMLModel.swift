//
//  CoreMLModel.swift
//  CoreMLPlayer
//
//  Created by NA on 1/21/23.
//

import SwiftUI
import CoreML
import Vision

class CoreMLModel: Base, ObservableObject {
    @Published var isValid = false
    @Published var isLoading = false
    @Published var name: String?
    
    @AppStorage("CoreMLModel-selectedBuiltInModel") var selectedBuiltInModel: String?
    @AppStorage("CoreMLModel-autoloadSelection") var autoloadSelection: AutoloadChoices = .disabled
    @AppStorage("CoreMLModel-bookmarkData") var bookmarkData: Data?
    @AppStorage("CoreMLModel-originalModelURL") var originalModelURL: URL?
    @AppStorage("CoreMLModel-compiledModelURL") var compiledModelURL: URL?
    @AppStorage("CoreMLModel-computeUnits") var computeUnits: MLComputeUnits = .all
    @AppStorage("CoreMLModel-gpuAllowLowPrecision") var gpuAllowLowPrecision: Bool = false
    
    var model: VNCoreMLModel?
    var modelDescription: [ModelDescription] = []
    var idealFormat: (width: Int, height: Int, type: OSType)?
    
    enum AutoloadChoices: String, CaseIterable, Identifiable {
        case disabled = "Disabled"
        case reloadCompiled = "Reload compiled cache" // Available until system reboot/shutdown
        case recompile = "Compile again"
        
        var id: String { self.rawValue }
    }
    
//    var modelType: CMPModelTypes = .unacceptable
//    enum CMPModelTypes: String {
//        case imageObjectDetection = "Object Detection"
//        case imageClassification = "Classification"
//        case unacceptable = "Unacceptable"
//    }
    
    func autoload() {
        switch autoloadSelection {
        case .disabled:
            bookmarkData = nil
            selectedBuiltInModel = nil
            return
        case .reloadCompiled:
            if let selectedBuiltInModel {
                loadBuiltInModel(name: selectedBuiltInModel)
            } else if let compiledModelURL {
                if FileManager.default.fileExists(atPath: compiledModelURL.path) {
                    loadTheModel(url: compiledModelURL)
                } else {
                    fallthrough // Fall Through to recompile from Bookmark
                }
            }
        case .recompile:
            if let selectedBuiltInModel {
                loadBuiltInModel(name: selectedBuiltInModel)
            } else if let url = loadBookmark() {
                loadTheModel(url: url, useSecurityScope: true)
            }
        }
    }
    
    func loadBuiltInModel(name: String) {
        if let builtInModelURL = Bundle.main.url(forResource: name, withExtension: "mlmodelc") {
            selectedBuiltInModel = name
            loadTheModel(url: builtInModelURL, useSecurityScope: false)
        } else {
            selectedBuiltInModel = nil
            showAlert(title: "Failed to load built-in model (\(name)) from app bundle!")
        }
    }
    
    func reconfigure() {
        if let compiledModelURL {
            loadTheModel(url: compiledModelURL, useSecurityScope: true)
        }
    }
    
    func bookmarkModel() {
        if loadBookmark() == originalModelURL {
            return
        } else if let modelUrl = originalModelURL, autoloadSelection != .disabled {
            saveBookmark(modelUrl)
        }
    }
    
    func loadTheModel(url: URL, useSecurityScope: Bool = false) {
        self.isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if useSecurityScope {
                    _ = url.startAccessingSecurityScopedResource()
                }
                
                var getCompiledURL: URL?
                var URLIsCompiled = false
                
                if url.pathExtension == "mlmodelc" { // mlmodel"c" is compiled
                    getCompiledURL = url
                    URLIsCompiled = true
                } else {
                    getCompiledURL = try MLModel.compileModel(at: url)
                }
                
                guard let compiledURL = getCompiledURL else {
                    throw URLError(.badURL)
                }
                
                let config = MLModelConfiguration()
                config.computeUnits = self.computeUnits
                config.allowLowPrecisionAccumulationOnGPU = self.gpuAllowLowPrecision
                
                let mlModel = try MLModel(contentsOf: compiledURL, configuration: config)
                try super.checkModelIO(modelDescription: mlModel.modelDescription)
                
                let vnModel = try VNCoreMLModel(for: mlModel)
                
                DispatchQueue.main.async {
                    if useSecurityScope {
                        url.stopAccessingSecurityScopedResource()
                    }
                    if !URLIsCompiled && !useSecurityScope {
                        self.originalModelURL = url
                        self.bookmarkModel()
                    }
                    self.compiledModelURL = compiledURL
                    self.model = vnModel
                    self.setModelDescriptionInfo(mlModel.modelDescription)
                    self.name = url.lastPathComponent
                    withAnimation {
                        self.isValid = true
                        self.isLoading = false
                    }
                }
            } catch {
                #if DEBUG
                print(error)
                #endif
                DispatchQueue.main.async {
                    if useSecurityScope {
                        url.stopAccessingSecurityScopedResource()
                    }
                    self.unSelectModel()
                    super.showAlert(title: "Failed to compile/initiate your MLModel!")
                }
            }
        }
    }
    
    func unSelectModel() {
        autoloadSelection = .disabled
        originalModelURL = nil
        compiledModelURL = nil
        selectedBuiltInModel = nil
        modelDescription = []
        bookmarkData = nil
        model = nil
        name = nil
        withAnimation {
            isValid = false
            isLoading = false
        }
    }
    
    func getModelURLString() -> (original: (file: String, directory: String), compiled: (file: String, directory: String)) {
        var originalFile = ""
        var originalDirectory = ""
        var compiledFile = ""
        var compiledDirectory = ""
        
        if let url = originalModelURL {
            originalFile = String(url.path)
            originalDirectory = url.deletingLastPathComponent().path()
        }
        
        if let url = compiledModelURL {
            compiledFile = String(url.path)
            compiledDirectory = url.deletingLastPathComponent().path()
        }
        
        return (original: (file: originalFile, directory: originalDirectory), compiled: (file: compiledFile, directory: compiledDirectory))
    }
    
    func selectCoreMLModel() {
        let file = super.selectFiles(contentTypes: K.CoreMLModel.contentTypes, multipleSelection: false)
        
        guard let selectedFile = file?.first else { return }
        selectedBuiltInModel = nil
        loadTheModel(url: selectedFile)
    }
    
    func setModelDescriptionInfo(_ coreMLModelDescription: MLModelDescription?) { //  MLModelDescription.h
        var info: [ModelDescription] = []
        guard let description = coreMLModelDescription else {
            modelDescription = []
            return
        }
        
        var inputDescriptionItems: [ModelDescription.Item] = []
        for item in description.inputDescriptionsByName {
            inputDescriptionItems.append(ModelDescription.Item(key: item.key, value: "\(item.value)"))
            if let image = item.value.imageConstraint {
                idealFormat = (width: image.pixelsWide, height: image.pixelsHigh, type: image.pixelFormatType)
            }
        }
        info.append(ModelDescription(category: "Input Description", items: inputDescriptionItems))
        
        var outputDescriptionItems: [ModelDescription.Item] = []
        for item in description.outputDescriptionsByName {
            outputDescriptionItems.append(ModelDescription.Item(key: item.key, value: "\(item.value)"))
        }
        info.append(ModelDescription(category: "Output Description", items: outputDescriptionItems))
        
        var metaDataItems: [ModelDescription.Item] = []
        for metaData in description.metadata {
            let key = metaData.key.rawValue.replacingOccurrences(of: "Key", with: "")
            let value = String(describing: metaData.value)
            
            if key == "MLModelCreatorDefined", let creatorDefinedItems = description.metadata[MLModelMetadataKey.creatorDefinedKey] as? NSDictionary {
                for creatorDefined in creatorDefinedItems {
                    metaDataItems.append(ModelDescription.Item(key: "\(creatorDefined.key)", value: "\(creatorDefined.value)"))
                }
            } else {
                metaDataItems.append(ModelDescription.Item(key: key, value: value))
            }
        }
        info.append(ModelDescription(category: "MetaData", items: metaDataItems))
        
        if let predictedFeatureName = description.predictedFeatureName {
            info.append(ModelDescription(category: "Predicted Feature Name", items: [ModelDescription.Item(key: "predictedFeatureName", value: predictedFeatureName)]))
        }
        
        if let predictedProbabilitiesName = description.predictedProbabilitiesName {
            info.append(ModelDescription(category: "Predicted Probabilities Name", items: [ModelDescription.Item(key: "predictedProbabilitiesName", value: predictedProbabilitiesName)]))
        }
        
        if let classLabels = description.classLabels {
            var classLabelItems: [ModelDescription.Item] = []
            for item in classLabels {
                classLabelItems.append(ModelDescription.Item(key: "\(item)", value: ""))
            }
            info.append(ModelDescription(category: "Class Labels", items: classLabelItems))
        }
        
        modelDescription = info
    }
    
    func saveBookmark(_ url: URL) {
        do {
            bookmarkData = try url.bookmarkData(
                options: [.securityScopeAllowOnlyReadAccess, .withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            #if DEBUG
            print("Failed to save bookmark data for \(url)", error)
            #endif
        }
    }
    
    func loadBookmark() -> URL? {
        guard let data = bookmarkData else { return nil }
        
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {
                saveBookmark(url)
            }
            return url
        } catch {
            #if DEBUG
            print("Error resolving bookmark:", error)
            #endif
            return nil
        }
    }
}
