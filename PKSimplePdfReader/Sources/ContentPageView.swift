//
//  ContentPageView.swift
//  PKSimplePdfReader
//
//  Created by K.Nakano on 2018/08/13.
//  Copyright © 2018 K.Nakano. All rights reserved.
//

import PDFKit

class ContentPageView: UIView {
    
    private var pdfPage: PDFPage
    private var unitCroppedRect: CGRect
    
    deinit {
        #if DEBUG
        print(#file, #function, #line)
        #endif
    }
    
    class override var layerClass : AnyClass {
        return ContentTile.self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init?(frame: CGRect, pdfPage: PDFPage, unitCroppedRect: CGRect) {
        self.pdfPage = pdfPage
        self.unitCroppedRect = unitCroppedRect
        super.init(frame: frame)
        
        self.isUserInteractionEnabled = false
        
        // for better performance
        self.layer.drawsAsynchronously = true
        self.layer.isOpaque = true
    }
    
    override func removeFromSuperview() {
        self.layer.delegate = nil
        self.layer.contents = nil
        super.removeFromSuperview()
    }
    
    /// Draw pdf content.
    ///
    override func draw(_ layer: CALayer, in context: CGContext) {
        // Avoid crashing.
        guard let _ = pdfPage.pageRef else { return }
        
        UIGraphicsPushContext(context)
        context.saveGState()

        // Fill the background with white.
        context.setFillColor(UIColor.white.cgColor)
        context.fill(context.boundingBoxOfClipPath)

        // Change the origin and the scale.
        // Assume that the aspect ratio of the layer matches that of unitCroppedRect.
        let box = pdfPage.bounds(for: .cropBox)
        let wScale = layer.bounds.width / (box.width * unitCroppedRect.width)
        let hScale = layer.bounds.height / (box.height * unitCroppedRect.height)
        let zoomScale = max(wScale, hScale)
        context.translateBy(x: -box.width * zoomScale * unitCroppedRect.origin.x,
                            y: box.height * zoomScale * (1 - unitCroppedRect.origin.y))
        context.scaleBy(x: zoomScale, y: -zoomScale)
        
        // Render the PDF page into the context
        pdfPage.draw(with: .cropBox, to: context)
        //if let pageRef = pdfPage.pageRef { context.drawPDFPage(pageRef) }
        
        context.restoreGState()
        UIGraphicsPopContext()
    }
    
}


// MARK: - ContentTile

class ContentTile: CATiledLayer {
    
    private let kLevelsOfDetail = 4
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Required for Debug View Hierarchy.
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    override init() {
        super.init()
        self.levelsOfDetail = kLevelsOfDetail
        self.levelsOfDetailBias = kLevelsOfDetail - 1
        let mainScreen = UIScreen.main
        let screenScale = mainScreen.scale
        let screenBounds = mainScreen.bounds
        let wPixels = screenBounds.size.width * screenScale
        let hPixels = screenBounds.size.height * screenScale
        let maxPixels = max(wPixels, hPixels)
        let sizeOfTiles: CGFloat = maxPixels < 512.0 ? 512.0 : 1024.0
        self.tileSize = CGSize(width: sizeOfTiles, height: sizeOfTiles)
    }
    
    class override func fadeDuration() -> CFTimeInterval {
        return 0.001
    }
    
}
