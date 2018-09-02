//
//  ScrollView.swift
//  PKSimplePdfReader
//
//  Created by K.Nakano on 2018/08/13.
//  Copyright © 2018 K.Nakano. All rights reserved.
//

import PDFKit

class ScrollView: UIScrollView {
    /// Maximum zoom scale
    private let kZoomMaximum: CGFloat = 4.0
    
    private weak var containerView: UIView!
    private weak var contentPageView: ContentPageView!
    private var realMaximumZoom: CGFloat = 0.0
    
    deinit {
        #if DEBUG
        print(#file, #function, #line)
        #endif
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init?(frame: CGRect, pdfPage: PDFPage) {
        super.init(frame: frame)
        self.scrollsToTop = false
        self.delaysContentTouches = false
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.clipsToBounds = false
        self.delegate = self
        // Always get under the navigation bar.
        self.contentInsetAdjustmentBehavior = .never
        
        // Create a background image.
        let box = pdfPage.bounds(for: .cropBox)
        let wScale = bounds.width / box.width
        let hScale = bounds.height / box.height
        var scale = max(wScale, hScale)
        scale *= 1.0 //UIScreen.main.scale(Clear but too slow on some pdfs...)
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let imageSize = box.size.applying(transform)
        let bgImage = pdfPage.thumbnail(of: imageSize, for: .cropBox)
        
        // Create a background image layer.
        let container = UIView(frame: frame)
        let layer = CALayer()
        //layer.contentsScale = UIScreen.main.scale
        layer.frame = container.layer.bounds
        layer.contents = bgImage.cgImage
        // crop!!
        let unitCroppedRect = PKCurlReader.info.unitCroppedRect
        layer.contentsRect = unitCroppedRect

        container.layer.addSublayer(layer)
        container.isUserInteractionEnabled = false
        // shadow
        container.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        container.layer.shadowRadius = 3.0
        container.layer.shadowOpacity = 1.0
        container.layer.shadowPath = UIBezierPath(rect: container.bounds).cgPath
        
        // Create a view with detailed PDF image.
        guard let content = ContentPageView(frame: frame,
                                            pdfPage: pdfPage,
                                            unitCroppedRect: unitCroppedRect) else {
            return nil
        }
        self.contentSize = content.bounds.size
        
        self.centerScrollViewContent()
        
        self.addSubview(container)
        container.addSubview(content)
        
        self.containerView = container
        self.contentPageView = content
        
        self.updateMinimumMaximumZoom()
        // Set the zoom scale to fit page content.
        self.zoomScale = self.minimumZoomScale
    }
    
    private func updateMinimumMaximumZoom() {
        let wScale: CGFloat = self.bounds.width / contentPageView.bounds.width
        let hScale: CGFloat = self.bounds.height / contentPageView.bounds.height
        let zoomScale = min(wScale, hScale)
        self.minimumZoomScale = zoomScale
        self.maximumZoomScale = zoomScale * kZoomMaximum
        realMaximumZoom = self.maximumZoomScale
    }
    
    private func centerScrollViewContent() {
        var iw: CGFloat = 0.0
        var ih: CGFloat = 0.0
        let boundsSize = self.bounds.size
        let contentSize = self.contentSize
        if contentSize.width < boundsSize.width { iw = (boundsSize.width - contentSize.width) * 0.5 }
        if contentSize.height < boundsSize.height { ih = (boundsSize.height - contentSize.height) * 0.5 }
        let insets = UIEdgeInsetsMake(ih, iw, ih, iw)
        if UIEdgeInsetsEqualToEdgeInsets(self.contentInset, insets) == false {
            self.contentInset = insets
        }
    }
}

// MARK: - UIScrollViewDelegate

extension ScrollView: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView;
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if self.zoomScale > realMaximumZoom {
            // Bounce back to real maximum zoom scale
            self.setZoomScale(realMaximumZoom, animated: true)
        }
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.centerScrollViewContent()
    }
}

