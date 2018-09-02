//
//  CropManipulateView.swift
//  PKSimplePdfReader
//
//  Created by K.Nakano on 2018/08/24.
//  Copyright © 2018 K.Nakano. All rights reserved.
//

class CropManipulateView: UIView {
    
    private let kMinimumUnitSize = CGSize(width: 0.1, height: 0.1)
    
    private var newPanRecognizer: UIPanGestureRecognizer {
        let recognizer = UIPanGestureRecognizer(target: self,
                                                action: #selector(panHandler(_:)))
        recognizer.maximumNumberOfTouches = 1
        return recognizer
    }
    private lazy var topHandle = CropHandleView(newPanRecognizer)
    private lazy var bottomHandle = CropHandleView(newPanRecognizer)
    private lazy var leftHandle = CropHandleView(newPanRecognizer)
    private lazy var rightHandle = CropHandleView(newPanRecognizer)
    private lazy var topLeftHandle = CropHandleView(newPanRecognizer)
    private lazy var topRightHandle = CropHandleView(newPanRecognizer)
    private lazy var bottomLeftHandle = CropHandleView(newPanRecognizer)
    private lazy var bottomRightHandle = CropHandleView(newPanRecognizer)
    
    /// PDF image rect.
    private var imageRect: CGRect {
        return pdfImageView.frame
    }
    
    private var pdfImageView: UIImageView
    
    private var unitCroppedRect: CGRect {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var croppedRect: CGRect {
        return CGRect(x: imageRect.origin.x + (imageRect.width * unitCroppedRect.origin.x),
                      y: imageRect.origin.y + (imageRect.height * unitCroppedRect.origin.y),
                      width: imageRect.width * unitCroppedRect.width,
                      height: imageRect.height * unitCroppedRect.height)
    }
    
    private var initialCroppedRect = CGRect.zero
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame: CGRect, pdfImageView: UIImageView) {
        self.pdfImageView = pdfImageView
        self.unitCroppedRect = PKCurlReader.info.unitCroppedRect
        super.init(frame: frame)
        
        // "You only need to set a value for the opaque property in subclasses of UIView
        // that draw their own content using the draw(_:) method."
        self.isOpaque = false
        
        addSubview(topHandle)
        addSubview(bottomHandle)
        addSubview(leftHandle)
        addSubview(rightHandle)
        addSubview(topLeftHandle)
        addSubview(topRightHandle)
        addSubview(bottomLeftHandle)
        addSubview(bottomRightHandle)
    }
    
    @objc private func panHandler(_ recognizer: UIPanGestureRecognizer) {
        // Disallow simultaneous operation of multiple handles.
        struct Static { static var targetHandleView: CropHandleView? }
        guard let handleView = recognizer.view as? CropHandleView else { return }
        if Static.targetHandleView == nil { Static.targetHandleView = handleView }
        guard handleView == Static.targetHandleView else { return }

        if recognizer.state == .began {
            initialCroppedRect = croppedRect
            recognizer.setTranslation(handleView.center, in: self)
        } else if recognizer.state == .changed {
            let newX = min(imageRect.maxX, max(imageRect.minX, recognizer.translation(in: self).x))
            let newY = min(imageRect.maxY, max(imageRect.minY, recognizer.translation(in: self).y))
            switch handleView {
            case topHandle: moveTopEdge(to: newY)
            case bottomHandle: moveBottomEdge(to: newY)
            case leftHandle: moveLeftEdge(to: newX)
            case rightHandle: moveRightEdge(to: newX)
            case topLeftHandle: moveTopEdge(to: newY); moveLeftEdge(to: newX)
            case topRightHandle: moveTopEdge(to: newY); moveRightEdge(to: newX)
            case bottomLeftHandle: moveBottomEdge(to: newY); moveLeftEdge(to: newX)
            case bottomRightHandle: moveBottomEdge(to: newY); moveRightEdge(to: newX)
            default: break
            }
            
        } else {
            Static.targetHandleView = nil
        }
    }
    
    private func moveTopEdge(to newY: CGFloat) {
        let unitY = (newY - imageRect.minY) / imageRect.height
        let unitYMax = unitCroppedRect.minY + unitCroppedRect.height - kMinimumUnitSize.height
        let unitH = (initialCroppedRect.maxY - newY) / imageRect.height
        unitCroppedRect.origin.y = min(unitY, unitYMax)
        unitCroppedRect.size.height = max(kMinimumUnitSize.height, unitH)
    }
    
    private func moveBottomEdge(to newY: CGFloat) {
        let unitH = (newY - initialCroppedRect.minY) / imageRect.height
        unitCroppedRect.size.height = max(kMinimumUnitSize.height, unitH)
    }
    
    private func moveLeftEdge(to newX: CGFloat) {
        let unitX = (newX - imageRect.minX) / imageRect.width
        let unitXMax = unitCroppedRect.minX + unitCroppedRect.width - kMinimumUnitSize.width
        let unitW = (initialCroppedRect.maxX - newX) / imageRect.width
        unitCroppedRect.origin.x = min(unitX, unitXMax)
        unitCroppedRect.size.width = max(kMinimumUnitSize.width, unitW)
    }
    
    private func moveRightEdge(to newX: CGFloat) {
        let unitW = (newX - initialCroppedRect.minX) / imageRect.width
        unitCroppedRect.size.width = max(kMinimumUnitSize.width, unitW)
    }
    
    private func arrangeHandles() {
        topHandle.center = CGPoint(x: croppedRect.midX, y: croppedRect.minY)
        bottomHandle.center = CGPoint(x: croppedRect.midX, y: croppedRect.maxY)
        leftHandle.center = CGPoint(x: croppedRect.minX, y: croppedRect.midY)
        rightHandle.center = CGPoint(x: croppedRect.maxX, y: croppedRect.midY)
        topLeftHandle.center = CGPoint(x: croppedRect.minX, y: croppedRect.minY)
        topRightHandle.center = CGPoint(x: croppedRect.maxX, y: croppedRect.minY)
        bottomLeftHandle.center = CGPoint(x: croppedRect.minX, y: croppedRect.maxY)
        bottomRightHandle.center = CGPoint(x: croppedRect.maxX, y: croppedRect.maxY)
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        // Fill background.
        context.setFillColor(UIColor(white: 0.0, alpha: 0.5).cgColor)
        context.fill(rect)
        // Draw borders.
        context.setLineWidth(2.0)
        context.setStrokeColor(UIColor.red.cgColor)
        context.stroke(croppedRect)
        // Cut a square.
        context.addRect(croppedRect)
        context.clip()
        context.clear(croppedRect)
        
        arrangeHandles()
    }
    
}
