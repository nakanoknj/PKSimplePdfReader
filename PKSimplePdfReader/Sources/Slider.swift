//
//  Slider.swift
//  PKSimplePdfReader
//
//  Created by K.Nakano on 2018/08/13.
//  Copyright © 2018 K.Nakano. All rights reserved.
//

protocol SliderDelegate: class {
    func onTouchDown(_ sender: Slider)
    func onValueChanged(_ sender: Slider)
    func onTouchCancel(_ sender: Slider)
}

class Slider: UISlider {
    
    weak var delegate: SliderDelegate?
    
    // Center of thumbRect at start of touch.
    private var beganTrackingLocation = CGPoint.zero
    /// Value at touch start.
    private var realPositionValue: Float = 0
    
    /// View to display thumbnails.
    ///
    lazy var thumbnailView: UIView = {
        let viewHeight = max(UIScreen.main.bounds.height, UIScreen.main.bounds.width) * 0.4
        let viewWidth = viewHeight * 3 / 4
        let tnView = UIView(frame: CGRect.zero)
        tnView.frame.size = CGSize(width: viewWidth, height: viewHeight)
        tnView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.8)
        tnView.layer.cornerRadius = 3.0
        
        let imageWidth = viewWidth / 6 * 5
        let imageHeight = imageWidth * 4 / 3
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        imageView.backgroundColor = UIColor.white
        
        let pageLabel = UILabel(frame: CGRect(x: 0,
                                              y: 0,
                                              width: viewWidth,
                                              height: (viewHeight - imageHeight) / 2))
        pageLabel.backgroundColor = UIColor.clear
        pageLabel.textColor = UIColor.white
        pageLabel.textAlignment = NSTextAlignment.center
        
        tnView.addSubview(pageLabel)
        tnView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.centerXAnchor.constraint(equalTo: tnView.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: tnView.centerYAnchor).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: imageWidth).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: imageHeight).isActive = true
        
        self.thumbnailImageView = imageView
        self.thumbnailLabel = pageLabel
        return tnView
    }()
    
    weak var thumbnailImageView: UIImageView?
    
    weak var thumbnailLabel: UILabel?
    
    var intValue: Int {
        return Int(self.value)
    }
    
    deinit {
        #if DEBUG
        print(#file, #function, #line)
        #endif
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame: CGRect, pageCount: Int) {
        super.init(frame: frame)
        minimumValue = 0
        maximumValue = Float(pageCount - 1)
        value = 0
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let beginTracking = super.beginTracking(touch, with: event)
        if beginTracking {
            let thumbRect = self.thumbRect(forBounds: self.bounds,
                                           trackRect: self.trackRect(forBounds: self.bounds),
                                           value: self.value)
            beganTrackingLocation = CGPoint(x: thumbRect.midX, y: thumbRect.midY)
            realPositionValue = self.value
            delegate?.onTouchDown(self)
        }
        return beginTracking
    }
    
    // This blog helped me a lot. Thanks!!
    // https://oleb.net/blog/2011/01/obslider-a-uislider-subclass-with-variable-scrubbing-speed/
    //
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        if self.isTracking {
            let previousLocation = touch.previousLocation(in: self)
            let currentLocation = touch.location(in: self)
            // The offset from the previous location.
            let trackingOffset = currentLocation.x - previousLocation.x
            // The offset from the starting position of thumbRect.
            let verticalOffset = fabs(currentLocation.y - beganTrackingLocation.y)
            // The Entire width that the thumbRect can move. (trackRect = Rect of "blue line" of the slider)
            let movableWidth = self.trackRect(forBounds: self.bounds).width
            // The ratio of the moving amount to the entire movable width
            let movementRatio = Float(trackingOffset / movableWidth)
            // The sliding range.
            let valueRange = self.maximumValue - self.minimumValue
            // Value with the speed of 1.0.
            realPositionValue = realPositionValue + valueRange * movementRatio
            // Adjust the speed according to the distance from thumbRect. (0.05 to 1.0)
            let speedVariableDistance = UIScreen.main.bounds.height * 0.5
            let offsetRatio = max(0, speedVariableDistance - verticalOffset) / speedVariableDistance
            let scrubbingSpeed = max(0.05, Float(ceil(offsetRatio * 10) / 10))
            // Adjust the value according to the speed.
            let valueAdjustment = scrubbingSpeed * valueRange * movementRatio
            // We are getting closer to the slider, go closer to the real location
            var thumbAdjustment: Float = 0
            if ( ((beganTrackingLocation.y < currentLocation.y) && (currentLocation.y < previousLocation.y)) ||
                ((beganTrackingLocation.y > currentLocation.y) && (currentLocation.y > previousLocation.y)) )
            {
                thumbAdjustment = (realPositionValue - self.value) /
                    Float(1 + fabs(currentLocation.y - beganTrackingLocation.y));
            }
            self.value += valueAdjustment + thumbAdjustment
            
            if self.isContinuous {
                delegate?.onValueChanged(self)
            }
        }
        return self.isTracking
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        if self.isTracking {
            // When calling super, value will be the actual finger position value,
            // so save before calling.
            let value = self.value
            
            super.endTracking(touch, with: event)
            self.value = value
            delegate?.onTouchCancel(self)
        }
    }
    
}
