//
//  VXRecognitionModel.swift
//  species
//
//  Created by Graham Lancashire on 18.06.19.
//  Copyright © 2019 Swift Management AG. All rights reserved.
//

import Foundation
import UIKit

public protocol VXRecognitionModelProtocol: class {
    func load(completion: @escaping (Bool) -> Void)
    func recognize(image: UIImage, completion: @escaping ([VXRecognitionPrediction]?) -> Void)
}

public struct VXRecognitionPrediction: Equatable {
    /// The name of the object, as predicted by Lumina
    public var name: String
    /// The numeric value of the confidence of the prediction, out of 1.0
    public var confidence: Float?
    public var date: Date? = Date()

    public static func == (lhs: VXRecognitionPrediction, rhs: VXRecognitionPrediction) -> Bool {
        let areEqual = lhs.name == rhs.name
        return areEqual
    }

    func color() -> UIColor? {
        switch confidence ?? 0.0 {
        case 0.9...:
            return UIColor.flatGreenDark.darken(byPercentage: 0.2)
        case 0.8 ..< 0.9:
            return UIColor.flatGreenDark.lighten(byPercentage: 0.1)
        case 0.7 ..< 0.8:
            return UIColor.flatGreen
        case 0.6 ..< 0.7:
            return UIColor.flatYellow
        case 0.5 ..< 0.6:
            return UIColor.flatYellowDark
        case 0.4 ..< 0.5:
            return UIColor.flatOrangeDark
        case 0.3 ..< 0.4:
            return UIColor.flatOrange
        case 0.2 ..< 0.3:
            return UIColor.flatRedDark
        case ..<0.2:
            return UIColor.flatRed
        default:
            return UIColor.clear
        }
    }
}
