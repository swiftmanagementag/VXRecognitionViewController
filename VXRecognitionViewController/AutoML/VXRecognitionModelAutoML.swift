//
//  VXRecognitionModel.swift
//  species
//
//  Created by Graham Lancashire on 18.06.19.
//  Copyright © 2019 Swift Management AG. All rights reserved.
//

import Foundation
import Firebase
import FirebaseMLCommon

class VXRecognitionModelAutoML: VXRecognitionModelProtocol {
    var detectionModel:String?
    var detectionThreshold:Float? = 0.0

    var downloadProgress: Progress?
    
    lazy var modelManager: ModelManager? = {
        return ModelManager.modelManager()
    }()
    
    lazy var labeler: VisionImageLabeler? = {
        
        let labelerOptions = VisionOnDeviceAutoMLImageLabelerOptions(
            remoteModelName: detectionModel,  // Or nil to not use a remote model
            localModelName: nil
        )
        labelerOptions.confidenceThreshold = detectionThreshold ?? 0.0 // Evaluate your model in the Firebase console
        // to determine an appropriate value.
        let labeler = Vision.vision().onDeviceAutoMLImageLabeler(options: labelerOptions)
        
        return labeler
    }()
    
    convenience init(detectionModel:String, detectionThreshold:Float? = 0.0) {
        self.init()
        self.detectionModel = detectionModel
        self.detectionThreshold = detectionThreshold
    }
    
    public func isModelOnDisk() -> Bool {
        guard let modelName =  self.detectionModel else {
            return false
        }
        
        let fm = FileManager.default
        if let appSupportDirectory = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let directory = appSupportDirectory.appendingPathComponent("com.google.firebase.ml.vision.automl.label").path
            
            // var isDirectory = ObjCBool(true)
            
            if fm.fileExists(atPath: "\(directory)/__FIRAPP_DEFAULT/\(modelName)/modelV0/model.tflite") || fm.fileExists(atPath: "\(directory)/__FIRAPP_DEFAULT/\(modelName)/modelV1/model.tflite") {
                return true
            //} else if fm.fileExists(atPath: directory, isDirectory: &isDirectory) {
            //    do {
            //        try fm.removeItem(atPath: directory)
            //    } catch {
            //        print(error.localizedDescription)
            //    }
            //    return false
            } else {
                return false
            }
        } else {
            return false
        }
        
        
    }
    public func load(completion: @escaping (Bool) -> Void) {
        let initialConditions = ModelDownloadConditions(allowsCellularAccess: true, allowsBackgroundDownloading: true)
        let updateConditions = ModelDownloadConditions(allowsCellularAccess: false, allowsBackgroundDownloading: true)
        
        let remoteModel = RemoteModel(
            name: detectionModel ?? "",
            allowsModelUpdates: true,
            initialConditions: initialConditions,
            updateConditions: updateConditions
        )
        self.modelManager?.register(remoteModel)
        
        if let mm = self.modelManager, mm.isRemoteModelDownloaded(remoteModel) && self.isModelOnDisk() {
            debugPrint("The model was downloaded and is available on the device")
            DispatchQueue.main.async(execute: {
                completion(true)
            })
        } else {
            debugPrint("Downloading model")
            self.downloadProgress = self.modelManager?.download(remoteModel)
            
            if let p = downloadProgress, p.isFinished {
                // The model is available on the device
                debugPrint("Downloaded model")
                completion(true)
            } else {
                
                NotificationCenter.default.addObserver(forName: .firebaseMLModelDownloadDidSucceed, object: nil, queue: nil) { notification in
                    guard let userInfo = notification.userInfo,
                        let model = userInfo[ModelDownloadUserInfoKey.remoteModel.rawValue] as? RemoteModel,
                        model.name == self.detectionModel
                        else { return }
                    debugPrint("The model was downloaded and is available on the device")
                    completion(true)
                }
                
                NotificationCenter.default.addObserver(forName: .firebaseMLModelDownloadDidFail, object: nil, queue: nil) { notification in
                    guard let userInfo = notification.userInfo
                        else { return }
                    let error = userInfo[ModelDownloadUserInfoKey.error.rawValue]
                    print(error ?? "error")
                    completion(false)
                }
            }
        }
        
    }
    public func recognize(image: UIImage, completion: @escaping ([VXRecognitionPrediction]?) -> Void) {
        // here you can take the image called videoFrame and handle it however you'd like
        let visionImage = VisionImage(image: image)
        self.labeler?.process(visionImage) { labels, error in
            if let e = error {
                print(e.localizedDescription)
                return
            } else {
                guard let labels = labels, labels.count > 0 else {
                    print("no labels found")
                    return
                }
                
                var predictions = [VXRecognitionPrediction]()
                
                for label in labels {
                    let prediction = VXRecognitionPrediction(name: label.text, confidence: label.confidence as? Float, date: Date())
                    predictions.append(prediction)
                }
                completion(predictions)
            }
            
        }
    }
}
