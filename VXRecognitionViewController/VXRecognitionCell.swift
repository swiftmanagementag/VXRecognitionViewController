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
    public var prediction: VXRecognitionPrediction?

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
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner]
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
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner]

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
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]

        return view
    }()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override required init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    func setup() {
        backgroundColor = UIColor.clear

        // photoview
        contentView.addSubview(photoView)
        photoView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            photoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            photoView.topAnchor.constraint(equalTo: contentView.topAnchor),
            photoView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            photoView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
        ])

        //  label background view
        contentView.addSubview(labelBackgroundView)
        labelBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelBackgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            labelBackgroundView.heightAnchor.constraint(equalToConstant: 48.0),
            labelBackgroundView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            labelBackgroundView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
        ])

        //  title label
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.bottomAnchor.constraint(equalTo: labelBackgroundView.bottomAnchor),
            titleLabel.topAnchor.constraint(equalTo: labelBackgroundView.topAnchor),
            titleLabel.leftAnchor.constraint(equalTo: labelBackgroundView.leftAnchor, constant: 4.0),
            titleLabel.rightAnchor.constraint(equalTo: labelBackgroundView.rightAnchor, constant: -4.0),
        ])

        //  confidence label
        contentView.addSubview(confidenceLabel)
        confidenceLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            confidenceLabel.widthAnchor.constraint(equalToConstant: 48.0),
            confidenceLabel.heightAnchor.constraint(equalToConstant: 40.0),
            confidenceLabel.topAnchor.constraint(equalTo: photoView.topAnchor, constant: 0),
            confidenceLabel.rightAnchor.constraint(equalTo: photoView.rightAnchor, constant: 0),
        ])

        confidenceLabel.isHidden = true
    }

    func size() -> CGSize {
        return size(UIUserInterfaceSizeClass.regular)
    }

    func size(_ sizeClass: UIUserInterfaceSizeClass) -> CGSize {
        return CollectionViewCellImage.defaultSize(sizeClass)
    }

    class func defaultSize(_ sizeClass: UIUserInterfaceSizeClass = UIUserInterfaceSizeClass.regular) -> CGSize {
        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width

        var columns = 2
        switch screenWidth {
        case 0 ..< 321:
            columns = (sizeClass == .compact) ? 2 : 2
        case 322 ..< 479:
            columns = (sizeClass == .compact) ? 3 : 2
        case 480 ..< 768:
            columns = (sizeClass == .compact) ? 4 : 3
        case 769 ..< CGFloat.greatestFiniteMagnitude:
            columns = (sizeClass == .compact) ? 7 : 5
        default:
            columns = (sizeClass == .compact) ? 5 : 2
        }
        let margin = COLUMN_MARGIN

        let size: CGFloat = floor((screenWidth - CGFloat(columns - 1) * margin) / CGFloat(columns)) - (32.0 / CGFloat(columns))
        return CGSize(width: size, height: size)
    }
}
