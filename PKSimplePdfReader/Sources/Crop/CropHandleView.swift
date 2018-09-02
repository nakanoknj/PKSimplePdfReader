//
//  CropHandleView.swift
//  PKSimplePdfReader
//
//  Created by K.Nakano on 2018/08/24.
//  Copyright © 2018 K.Nakano. All rights reserved.
//

class CropHandleView: UIView {
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(_ recognizer: UIGestureRecognizer) {
        super.init(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        self.addGestureRecognizer(recognizer)
        self.backgroundColor = UIColor.clear
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        var handleRect = CGRect(x: 0, y: 0, width: 10, height: 10)
        handleRect.origin.x = (rect.width - handleRect.width) / 2
        handleRect.origin.y = (rect.height - handleRect.height) / 2
        // Make the background transparent.
        context.setFillColor(UIColor.white.cgColor)
        context.fill(handleRect)
        // Draw rect.
        context.setLineWidth(1.0)
        context.setStrokeColor(UIColor.red.cgColor)
        context.stroke(handleRect)
    }
}
