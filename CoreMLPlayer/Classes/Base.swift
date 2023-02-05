//
//  Base.swift
//  CoreML Player
//
//  Created by NA on 1/22/23.
//

import SwiftUI
import UniformTypeIdentifiers
import Vision

class Base {
    typealias detectionOutput = (objects: [DetectedObject], detectionTime: String, detectionFPS: String)
    let emptyDetection: detectionOutput = ([], "", "")
    
    func selectFiles(contentTypes: [UTType], multipleSelection: Bool = true) -> [URL]? {
        let picker = NSOpenPanel()
        picker.allowsMultipleSelection = multipleSelection
        picker.allowedContentTypes = contentTypes
        picker.canChooseDirectories = false
        picker.canCreateDirectories = false
        
        if picker.runModal() == .OK {
            return picker.urls
        }
        
        return nil
    }
    
    // Old-style Alert is less work on Mac
    func showAlert(title: String, message: String? = nil) {
        let alert = NSAlert()
        alert.messageText = title
        if let message {
            alert.informativeText = message
        }
        alert.runModal()
    }
    
    func detectImageObjects(image: ImageFile?, model: VNCoreMLModel?) -> detectionOutput {
        guard let vnModel = model,
              let nsImage = image?.getNSImage()
        else {
            return emptyDetection
        }
        
        guard let tiffImage = nsImage.tiffRepresentation else {
            showAlert(title: "Failed to convert image!")
            return emptyDetection
        }
        
        return performObjectDetection(requestHandler: VNImageRequestHandler(data: tiffImage), vnModel: vnModel)
    }
    
    func performObjectDetection(requestHandler: VNImageRequestHandler, vnModel: VNCoreMLModel) -> detectionOutput {
        var observationResults: [VNObservation]?
        let request = VNCoreMLRequest(model: vnModel) { (request, error) in
            observationResults = request.results
        }
        
        request.imageCropAndScaleOption = .scaleFill
        
        
        let detectionTime = ContinuousClock().measure {
            try? requestHandler.perform([request])
        }
        
        return asDetectedObjects(visionObservationResults: observationResults, detectionTime: detectionTime)
    }
    
    func asDetectedObjects(visionObservationResults: [VNObservation]?, detectionTime: Duration) -> detectionOutput {
        let classificationObservations = visionObservationResults as? [VNClassificationObservation]
        let objectObservations = visionObservationResults as? [VNRecognizedObjectObservation]

        var detectedObjects: [DetectedObject] = []
        
        let msTime = detectionTime.formatted(.units(allowed: [.seconds, .milliseconds], width: .narrow))
        let detectionFPS = String(format: "%.0f", Duration.seconds(1) / detectionTime)
        
        var labels: [(label: String, confidence: String)] = []
        
        // TODO: Implement more model types, and improve classificationObservations
        
        if let objectObservations // VNRecognizedObjectObservation
        {
            for obj in objectObservations {
                labels = []
                for l in obj.labels {
                    labels.append((label: l.identifier, confidence: String(format: "%.4f", l.confidence)))
                }
                
                let newObject = DetectedObject(
                    id: obj.uuid,
                    label: obj.labels.first?.identifier ?? "",
                    confidence: String(format: "%.3f", obj.confidence),
                    otherLabels: labels,
                    width: obj.boundingBox.width,
                    height: obj.boundingBox.height,
                    x: obj.boundingBox.origin.x,
                    y: obj.boundingBox.origin.y
                )
                
                detectedObjects.append(newObject)
            }
        }
        else if let classificationObservations, let mainObject = classificationObservations.first // VNClassificationObservation
        {
            // For now:
            for c in classificationObservations {
                labels.append((label: c.identifier, confidence: String(format: "%.4f", c.confidence)))
            }
            let label = "\(mainObject.identifier) (\(mainObject.confidence))"
            let newObject = DetectedObject(
                id: mainObject.uuid,
                label: label, //mainObject.identifier,
                confidence: String(format: "%.3f", mainObject.confidence),
                otherLabels: labels,
                width: 0.9,
                height: 0.85,
                x: 0.05,
                y: 0.05,
                isClassification: true
            )
            detectedObjects.append(newObject)
            #if DEBUG
            print("Classification Observation:")
            print(classificationObservations)
            #endif
        }
        else
        {
            #if DEBUG
            print("No objects found.")
            #endif
        }
        
        return (objects: detectedObjects, detectionTime: msTime, detectionFPS: detectionFPS)
    }
    
    func checkModelIO(modelDescription: MLModelDescription) throws {
        if !modelDescription.inputDescriptionsByName.contains(where: { $0.key.contains("image") }) {
            DispatchQueue.main.async {
                self.showAlert(title: "This model does not accept Images as an input, and at the moment is not supported.")
            }
            throw MLModelError(.io)
        }
        
        if !modelDescription.outputDescriptionsByName.contains(where: { $0.key.contains("coordinate") || $0.key.contains("confidence") || $0.key.contains("class") }) {
            DispatchQueue.main.async {
                self.showAlert(title: "This model is not of type Object Detection or Classification, and at the moment is not supported.")
            }
            throw MLModelError(.io)
        }
    }
    
    func prepareObjectForSwiftUI(object: DetectedObject, geometry: GeometryProxy) -> CGRect {
        let objectRect = CGRect(x: object.x, y: object.y, width: object.width, height: object.height)
        
        return rectForNormalizedRect(normalizedRect: objectRect, width: Int(geometry.size.width), height: Int(geometry.size.height))
    }
    
    func rectForNormalizedRect(normalizedRect: CGRect, width: Int, height: Int) -> CGRect {
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -CGFloat(height))
        return VNImageRectForNormalizedRect(normalizedRect, width, height).applying(transform)
    }
}

extension NSImage {
    // Without this NSImage returns size in points not pixels
    var actualSize: NSSize {
        guard representations.count > 0 else { return .zero }
        return NSSize(width: representations[0].pixelsWide, height: representations[0].pixelsHigh)
    }
}

extension VNRecognizedObjectObservation: Identifiable {
    public var id: UUID {
        return self.uuid
    }
    static func ==(lhs: VNRecognizedObjectObservation, rhs: VNRecognizedObjectObservation) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}
