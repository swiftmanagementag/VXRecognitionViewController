//
//  VXRecognitionModel.swift
//  species
//
//  Created by Graham Lancashire on 18.06.19.
//  Copyright © 2019 Swift Management AG. All rights reserved.
//

import CoreML
import Foundation
import Vision
import Zip

class VXRecognitionModelCoreML: NSObject, VXRecognitionModelProtocol {
    var model: MLModel?
    var detectionModel: String?
    var detectionModelUrl: URL?

    static let modelExtension = "mlmodel"
    static let compiledExtension = "mlmodelc"
    static let resourceExtenstion = "cmlc"
    static let compressedExtenstion = "zip"
    static let threshhold = 0.2

    lazy var labeler: VNCoreMLModel? = {
        guard let model = self.model else { return nil }

        var labeler: VNCoreMLModel?

        do {
            labeler = try VNCoreMLModel(for: model)
        } catch {
            print(error.localizedDescription)
        }

        return labeler
    }()

    convenience init(detectionModel: String, detectionModelUrl: URL?) {
        self.init()
        self.detectionModel = detectionModel
        self.detectionModelUrl = detectionModelUrl
    }

    public func load(completion: @escaping (Bool) -> Void) {
        // model is loaded and ready to go
        if model != nil {
            debugPrint("The model ready to go")
            completion(true)
        }

        // get base directory
        let documentsDirectoryURL = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first! as URL

        // check if the compiled model is present, load it
        let compiledURL = documentsDirectoryURL.appendingPathComponent((detectionModel ?? "") + "." + VXRecognitionModelCoreML.compiledExtension)
        if FileManager.default.fileExists(atPath: compiledURL.path) {
            debugPrint("The model is compiled and needs to be loaded")
            do {
                model = try MLModel(contentsOf: compiledURL)
                debugPrint("The model is loaded and ready")
                completion(true)
            } catch {
                debugPrint(error.localizedDescription)

                print(error.localizedDescription)

                // try to delete as the file is invalid
                do {
                    try FileManager.default.removeItem(at: compiledURL)
                } catch {
                    print(error.localizedDescription)
                }
                completion(false)
            }
        } else {
            // check if the model is present
            let modelURL = documentsDirectoryURL.appendingPathComponent((detectionModel ?? "") + "." + VXRecognitionModelCoreML.modelExtension)

            if FileManager.default.fileExists(atPath: modelURL.path) {
                debugPrint("The source model is ready and needs to be compiled and loaded")

                do {
                    let compiledURL = try MLModel.compileModel(at: modelURL)
                    debugPrint("The model is compiled and needs to be loaded")
                    let destinationURL = documentsDirectoryURL.appendingPathComponent((detectionModel ?? "") + "." + VXRecognitionModelCoreML.compiledExtension)
                    try FileManager().moveItem(at: compiledURL, to: destinationURL)
                    model = try MLModel(contentsOf: destinationURL)
                    debugPrint("The model is loaded and ready")
                    completion(true)
                } catch {
                    print(error.localizedDescription)
                }
                completion(false)
            } else if let url = detectionModelUrl {
                let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
                    if let localURL = localURL, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                        let fileExtension = url.pathExtension

                        do {
                            var destination = documentsDirectoryURL.appendingPathComponent((self.detectionModel ?? "") + "." + fileExtension)

                            try FileManager().moveItem(at: localURL, to: destination)
                            print("File saved \(destination)")

                            if fileExtension == VXRecognitionModelCoreML.modelExtension {
                                let compiledURL = try MLModel.compileModel(at: destination)
                                destination = documentsDirectoryURL.appendingPathComponent((self.detectionModel ?? "") + "." + VXRecognitionModelCoreML.compiledExtension)
                                try FileManager().moveItem(at: compiledURL, to: destination)
                            }
                            self.model = try MLModel(contentsOf: destination)
                            debugPrint("The model is loaded and ready")

                            completion(true)

                        } catch {
                            print("Problem downloading \(response.debugDescription) \(error.localizedDescription)")
                            completion(false)
                        }
                    } else {
                        print("Problem downloading \(response?.debugDescription ?? "") \(error?.localizedDescription ?? "")")
                    }
                }
                task.resume()
            }
        }
    }

    func recognize(image: UIImage, completion: @escaping ([VXRecognitionPrediction]?) -> Void) {
        guard let coreImage = image.cgImage else {
            completion(nil)
            return
        }

        var predictions = [VXRecognitionPrediction]()
        guard let _ = model else { return }
        guard let labeler = self.labeler else { return }

        let request = VNCoreMLRequest(model: labeler) { request, error in
            if let e = error {
                print(e.localizedDescription)
            } else if request.results == nil {
                print("no results")
            } else if let results = request.results {
                for r in results {
                    if let o = r as? VNClassificationObservation {
                        if Double(o.confidence) > VXRecognitionModelCoreML.threshhold {
                            let name = NSLocalizedString(o.identifier, tableName: self.detectionModel ?? "", comment: o.identifier)

                            let prediction = VXRecognitionPrediction(name: name, confidence: o.confidence, date: Date())
                            predictions.append(prediction)
                        }
                    }
                }
                completion(predictions)
            }
        }
        let handler = VNImageRequestHandler(cgImage: coreImage)
        do {
            try handler.perform([request])
        } catch {
            print(error.localizedDescription)
        }
    }
}
