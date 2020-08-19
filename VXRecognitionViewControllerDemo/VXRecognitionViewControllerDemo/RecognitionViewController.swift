//
//  RecognitionViewController.swift
//  mushroom
//
//  Created by Graham Lancashire on 18.06.19.
//  Copyright © 2019 Swift Management AG. All rights reserved.
//

import Foundation
import UIKit

class RecognitionViewController: VXRecognitionViewController {
    // MARK: - View LifeCycle

    override func viewDidLoad() {
        // initialise if necessary
        if model == nil {
            // Configure model
            let detectionModel = "Oxford102"
            let detectionModelUrl = URL(string: "https://www.dropbox.com/s/7vx6nd5w86bo0bx/Oxford102.mlmodel?dl=1")

            model = VXRecognitionModelCoreML(detectionModel: detectionModel, detectionModelUrl: detectionModelUrl)
        }

        // Load model
        model?.load(completion: { _ in
            DispatchQueue.main.async {
                super.viewDidLoad()

                // Build temporary UI for Simulator
                if Platform.isSimulator {
                    if let image = UIImage(named: "logo.png") {
                        self.addPreviewImage(image: image)

                        for s in featured {
                            let prediction = VXRecognitionPrediction(name: s.code ?? "", confidence: (s.code == species.code) ? 0.8 : 0.25, date: Date())

                            self.predictions.append(prediction)
                        }
                        self.collectionView.reloadData()
                    }
                }
            }
        })
    }

    // MARK: - Configure cell content

    override func configureCell(_ cell: VXRecognitionCell, prediction: VXRecognitionPrediction) {
        super.configureCell(cell, prediction: prediction)
        let code = prediction.name.replacingOccurrences(of: "_", with: "-")

        cell.titleLabel.text = code
        cell.photoView.image = UIImage(named: "ico_photo@3x.png")?.withRenderingMode(.alwaysTemplate)
        cell.photoView.tintColor = UIColor.white
        if let confidence = prediction.confidence, confidence > 0.0 {
            cell.confidenceLabel.isHidden = false
            cell.confidenceLabel.text = "\(String(format: "%.0f%%", confidence * 100.0))"
            cell.confidenceLabel.backgroundColor = prediction.color()
        } else {
            cell.confidenceLabel.isHidden = true
        }
    }

    // MARK: - Handle detail tap

    // override func selectPrediction(_ prediction:VXRecognitionPrediction) {
    // super.selectPrediction(prediction)
    // }
}
