//
//  VXRecognitionViewCell.swift
//  species
//
//  Created by Graham Lancashire on 19.06.19.
//  Copyright © 2019 Swift Management AG. All rights reserved.
//

import Foundation
import UIKit

class VXRecognitionCell: UICollectionViewCell {
    
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var viewLabelBackground: UIView!
    
    var code:String? = nil
    
    func size() -> CGSize {
        return self.size(UIUserInterfaceSizeClass.regular)
    }
    
    func size(_ sizeClass:UIUserInterfaceSizeClass) -> CGSize {
        
        return CollectionViewCellImage.defaultSize(sizeClass)
    }
    class func defaultSize(_ sizeClass:UIUserInterfaceSizeClass = UIUserInterfaceSizeClass.regular) -> CGSize {
        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width
        
        var columns = 3
        switch screenWidth {
        case 0..<321:
            columns = (sizeClass == .compact) ? 3 : 3
        case 322..<479:
            columns = (sizeClass == .compact) ? 4 : 3
        case 480..<768:
            columns = (sizeClass == .compact) ? 5 : 4
        case 769..<CGFloat.greatestFiniteMagnitude:
            columns = (sizeClass == .compact) ? 8 : 6
        default:
            columns = (sizeClass == .compact) ? 6 : 4
        }
        let margin = COLUMN_MARGIN
        
        let size:CGFloat = floor((screenWidth - CGFloat(columns - 1) * margin) / CGFloat(columns))
        return CGSize(width: size, height: size);
    }
}
