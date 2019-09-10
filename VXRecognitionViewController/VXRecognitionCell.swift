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
    
    public var prediction:VXRecognitionPrediction? = nil
    
    lazy var photoView: UIImageView = {
        let view = UIImageView()
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = UIColor.clear
        view.isUserInteractionEnabled = false
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.borderColor = UIColor.black.cgColor
        view.layer.borderWidth = 3
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMaxYCorner,.layerMaxXMinYCorner, .layerMaxXMaxYCorner,.layerMinXMinYCorner]
        return view
    }()
    lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = UIColor.clear
        view.isUserInteractionEnabled = false
        view.textAlignment = .center
        view.numberOfLines = 2
        view.lineBreakMode = .byWordWrapping
        view.font = UIFont.spTableTitleFont()
        view.textColor = UIColor.white
        return view
    }()
    lazy var confidenceLabel: UILabel = {
        let view = UILabel()
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = UIColor.green
        view.textAlignment = .center
        view.isUserInteractionEnabled = false
        view.numberOfLines = 1
        view.font = UIFont.spTableTitleFont()
        view.textColor = UIColor.white
        view.clipsToBounds = true
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMaxYCorner,.layerMaxXMinYCorner]
        
        return view
    }()
    lazy var labelBackgroundView: UIView = {
        let view = UIView()
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = UIColor.darkGray
        view.isUserInteractionEnabled = false
        view.alpha = 0.6
        view.clipsToBounds = true
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMaxYCorner,.layerMaxXMaxYCorner]
        
        return view
    }()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    required override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    func setup() {
        self.backgroundColor = UIColor.clear
        
        // photoview
        self.contentView.addSubview(self.photoView)
        self.photoView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            self.photoView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            self.photoView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.photoView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.photoView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor),
            ])

        //  label background view
        self.contentView.addSubview(self.labelBackgroundView)
        self.labelBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.labelBackgroundView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            self.labelBackgroundView.heightAnchor.constraint(equalToConstant: 48.0),
            self.labelBackgroundView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.labelBackgroundView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor),
            ])

        
        //  title label
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            self.titleLabel.bottomAnchor.constraint(equalTo: self.labelBackgroundView.bottomAnchor),
            self.titleLabel.topAnchor.constraint(equalTo: self.labelBackgroundView.topAnchor),
            self.titleLabel.leftAnchor.constraint(equalTo: self.labelBackgroundView.leftAnchor, constant: 4.0),
            self.titleLabel.rightAnchor.constraint(equalTo: self.labelBackgroundView.rightAnchor, constant: -4.0),
            ])
        
        
        //  confidence label
        self.contentView.addSubview(self.confidenceLabel)
        self.confidenceLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.confidenceLabel.widthAnchor.constraint(equalToConstant: 48.0),
            self.confidenceLabel.heightAnchor.constraint(equalToConstant: 40.0),
            self.confidenceLabel.topAnchor.constraint(equalTo: self.photoView.topAnchor, constant: 0),
            self.confidenceLabel.rightAnchor.constraint(equalTo: self.photoView.rightAnchor, constant: 0),
            ])
        
        self.confidenceLabel.isHidden = true
    }
    

    func size() -> CGSize {
        return self.size(UIUserInterfaceSizeClass.regular)
    }
    
    func size(_ sizeClass:UIUserInterfaceSizeClass) -> CGSize {
        return CollectionViewCellImage.defaultSize(sizeClass)
    }
    class func defaultSize(_ sizeClass:UIUserInterfaceSizeClass = UIUserInterfaceSizeClass.regular) -> CGSize {
        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width
        
        var columns = 2
        switch screenWidth {
        case 0..<321:
            columns = (sizeClass == .compact) ? 2 : 2
        case 322..<479:
            columns = (sizeClass == .compact) ? 3 : 2
        case 480..<768:
            columns = (sizeClass == .compact) ? 4 : 3
        case 769..<CGFloat.greatestFiniteMagnitude:
            columns = (sizeClass == .compact) ? 7 : 5
        default:
            columns = (sizeClass == .compact) ? 5 : 2
        }
        let margin = COLUMN_MARGIN
        
        let size:CGFloat = floor((screenWidth - CGFloat(columns - 1) * margin) / CGFloat(columns)) - (32.0 / CGFloat(columns))
        return CGSize(width: size, height: size);
    }
}
