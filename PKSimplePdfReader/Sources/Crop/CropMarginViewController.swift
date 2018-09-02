//
//  CropMarginViewController.swift
//  PKSimplePdfReader
//
//  Created by K.Nakano on 2018/08/23.
//  Copyright © 2018 K.Nakano. All rights reserved.
//

import PDFKit

class CropMarginViewController: UIViewController {
    
    var onCropped: ((_ baseSize: CGSize) -> Void)
    
    private var pdfPage: PDFPage
    
    private var cropManipulateView: CropManipulateView!
    
    private lazy var doneButton: UIBarButtonItem = {
        let btn = UIBarButtonItem(barButtonSystemItem: .done,
                                  target: self,
                                  action: #selector(doneTapped))
        btn.tintColor = UIColor.white
        return btn
    }()
    
    private lazy var cancelButton: UIBarButtonItem = {
        let btn = UIBarButtonItem(barButtonSystemItem: .cancel,
                                  target: self,
                                  action: #selector(cancelTapped))
        btn.tintColor = UIColor.white
        return btn
    }()
    
    private func pdfImageViewSize(baseSize: CGSize) -> CGSize {
        let pdfSize = pdfPage.bounds(for: .cropBox).size
        let wScale = baseSize.width / pdfSize.width
        let hScale = baseSize.height / pdfSize.height
        let scale = min(wScale, hScale) * 0.8
        return CGSize(width: pdfSize.width * scale, height: pdfSize.height * scale)
    }
    
    private func pdfImage(baseSize: CGSize) -> UIImage {
        let imageViewSize = pdfImageViewSize(baseSize: baseSize)
        let zoomScale: CGFloat = 1.5 // 2.0
        let zoomTransform = CGAffineTransform(scaleX: zoomScale, y: zoomScale)
        let imageSize = imageViewSize.applying(zoomTransform)
        let pdfImage = pdfPage.thumbnail(of: imageSize, for: .cropBox)
        return pdfImage
    }

    private lazy var pdfImageView: UIImageView = {
        let baseSize = self.view.bounds.size
        let imageViewSize = pdfImageViewSize(baseSize: baseSize)
        let imageView = UIImageView(frame: CGRect(origin: CGPoint.zero, size: imageViewSize))
        imageView.contentMode = .scaleAspectFit
        imageView.image = self.pdfImage(baseSize: baseSize)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        pdfImageViewWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: imageViewSize.width)
        pdfImageViewHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: imageViewSize.height)
        pdfImageViewHeightConstraint?.isActive = true
        pdfImageViewWidthConstraint?.isActive = true
        return imageView
    }()

    private weak var pdfImageViewCenterYConstraint: NSLayoutConstraint?
    
    private weak var pdfImageViewHeightConstraint: NSLayoutConstraint?

    private weak var pdfImageViewWidthConstraint: NSLayoutConstraint?
    
    private weak var cropManipulateViewWidthConstraint: NSLayoutConstraint?
    
    private weak var cropManipulateViewHeightConstraint: NSLayoutConstraint?
    
    private lazy var topToolbar: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect.zero)
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                           target: nil,
                                           action: nil)
        let buttonItems = [flexibleItem, cancelButton, doneButton]
        toolbar.setItems(buttonItems, animated: false)
        // Make the background of toolbar transparent.
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbar.backgroundColor = UIColor(white: 0.2, alpha: 0.6)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        return toolbar
    }()
    
    deinit {
        #if DEBUG
        print(#file, #function, #line)
        #endif
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(pdfPage: PDFPage, cropped: @escaping (_ baseSize: CGSize) -> Void) {
        self.pdfPage = pdfPage
        self.onCropped = cropped
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add pdfImageView
        self.view.addSubview(pdfImageView)
        pdfImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        pdfImageViewCenterYConstraint =
            pdfImageView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor,constant: 0)
        pdfImageViewCenterYConstraint?.isActive = true

        // Add cropManipulateView
        cropManipulateView = CropManipulateView(frame: CGRect.zero, pdfImageView: pdfImageView)
        self.view.addSubview(cropManipulateView)
        cropManipulateView.translatesAutoresizingMaskIntoConstraints = false
        cropManipulateViewWidthConstraint =
            cropManipulateView.widthAnchor.constraint(equalToConstant: self.view.bounds.width)
        cropManipulateViewHeightConstraint =
            cropManipulateView.heightAnchor.constraint(equalToConstant: self.view.bounds.height)
        cropManipulateViewWidthConstraint?.isActive = true
        cropManipulateViewHeightConstraint?.isActive = true
        cropManipulateView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        cropManipulateView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        
        // Add topToolbar
        self.view.addSubview(topToolbar)
        topToolbar.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        topToolbar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        topToolbar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Adjust pdfImageView's y position.
        pdfImageViewCenterYConstraint?.constant = topToolbar.bounds.height / 2
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Resize pdfImageView.
        let viewSize = pdfImageViewSize(baseSize: size)
        pdfImageViewWidthConstraint?.constant = viewSize.width
        pdfImageViewHeightConstraint?.constant = viewSize.height
        pdfImageView.image = pdfImage(baseSize: size)
        
        // Resize cropManipulateView.
        cropManipulateViewWidthConstraint?.constant = size.width
        cropManipulateViewHeightConstraint?.constant = size.height
        cropManipulateView.setNeedsDisplay()
        self.view.layoutIfNeeded()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    /// Prevent dock from being displayed unintentionally.
    ///
    override func preferredScreenEdgesDeferringSystemGestures() -> UIRectEdge {
        return .bottom
    }
    
    @objc func doneTapped() {
        // Convert cropped rect to a unit coordinate system.
        let imageFrame = pdfImageView.frame
        let croppedRect = cropManipulateView.croppedRect
        var unitRect = CGRect.zero
        unitRect.origin.x = (croppedRect.minX - imageFrame.minX) / imageFrame.width
        unitRect.origin.y = (croppedRect.minY - imageFrame.minY) / imageFrame.height
        unitRect.size.width = croppedRect.width / imageFrame.width
        unitRect.size.height = croppedRect.height / imageFrame.height
        PKCurlReader.info.unitCroppedRect = unitRect
        
        onCropped(self.view.bounds.size)
        dismiss(animated: true, completion: nil)
    }
    
    @objc func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }
}
