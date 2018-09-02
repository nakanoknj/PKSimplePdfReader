//
//  ThumbnailCell.swift
//  PKSimplePdfReader
//
//  Created by K.Nakano on 2018/08/29.
//  Copyright © 2018 K.Nakano. All rights reserved.
//

class ThumbnailCell: UICollectionViewCell {
    
    private let kSelectedBorderWidth: CGFloat = 3
    
    lazy var pageLabel: UILabel = {
        let imageWidth = imageView.bounds.width
        let imageHeight = imageView.bounds.height
        let labelWidth = min(30, imageWidth * 0.25)
        let labelHeight = labelWidth
        let rect = CGRect(x: imageWidth - labelWidth - kSelectedBorderWidth,
                          y: kSelectedBorderWidth,
                          width: labelWidth,
                          height: labelHeight)
        let label = UILabel(frame: rect)
        label.textAlignment = NSTextAlignment.center
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont.systemFont(ofSize: labelWidth * 0.5)
        label.textColor = UIColor.white
        label.backgroundColor = UIColor(white: 0, alpha: 0.6)
        label.layer.masksToBounds = true
        label.layer.cornerRadius = labelWidth / 2
        return label
    }()
    
    lazy var imageView: UIImageView = {
        let imageHeight = bounds.height
        let imageWidth = imageHeight * 3 / 4
        let rect = CGRect(x: (bounds.width - imageWidth) / 2,
                          y: 0,
                          width: imageWidth,
                          height: imageHeight)
        let imageView = UIImageView(frame: rect)
        imageView.backgroundColor = UIColor.white
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        imageView.layer.cornerRadius = 2
        imageView.layer.shadowColor = UIColor.darkGray.cgColor
        imageView.layer.shadowOffset = CGSize(width: 5.0, height: 5.0);
        imageView.layer.shadowOpacity = 0.8
        return imageView
    }()
    
    override var isSelected: Bool {
        didSet {
            super.isSelected = isSelected
            imageView.layer.borderWidth = isSelected ? kSelectedBorderWidth : 0
            imageView.layer.borderColor = isSelected ? UIColor.red.cgColor : UIColor.clear.cgColor
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let imageView = self.imageView
        imageView.addSubview(pageLabel)
        contentView.addSubview(imageView)
    }
}
