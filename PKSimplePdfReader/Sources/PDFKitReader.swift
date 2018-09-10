//
//  PDFKitReader.swift
//  PKSimplePdfReader
//
//  Created by K.Nakano on 2018/09/10.
//  Copyright © 2018 K.Nakano. All rights reserved.
//

import PDFKit

//protocol SliderDelegate: class {
//    func onTouchDown(_ sender: Slider)
//    func onValueChanged(_ sender: Slider)
//    func onTouchCancel(_ sender: Slider)
//}

class PDFKitReader: UIViewController {

    static var info: ReaderInfo!

    /// For saving the setting of the transition source screen.
    ///
    private var presentsWithGestureOriginal: Bool?
    private var navigationBarHiddenOriginal: Bool?
    private var toolbarHiddenOriginal: Bool?
    private var statusBarHiddenDefault: Bool?
    /// Slider for page transition.
    ///
    private lazy var slider: Slider = {
        let slider = Slider(frame: CGRect(x: 0, y: 0, width: 600, height: 44),
                            pageCount: pdfDocument.pageCount)
        slider.value = Float(currentIndex)
        slider.delegate = self
        return slider
    }()
    /// Thumbnail image management class
    ///
    private var thumbnailStore: ThumbnailStore
    
    /// PDF Document
    ///
    private var pdfDocument: PDFDocument
    /// Index of currently displayed page
    ///
    private var currentIndex: Int {
        if let pageRef = pdfView.currentPage?.pageRef {
            return pageRef.pageNumber - 1
        }
        return 0
    }
    
    private lazy var pdfView: PDFView = {
        let pv = PDFView(frame: self.view.bounds)
        pv.backgroundColor = PDFKitReader.info.backgroundColor ?? UIColor.red
        pv.autoScales = true
        pv.usePageViewController(true, withViewOptions: nil)
        pv.displayDirection = .horizontal
        pv.minScaleFactor = pv.scaleFactorForSizeToFit;
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()

    private var statusBarHidden = false {
        didSet {
            navigationController?.setNavigationBarHidden(statusBarHidden, animated: false)
            navigationController?.setToolbarHidden(statusBarHidden, animated: false)
            if !statusBarHidden { slider.value = Float(currentIndex) }

            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    init?(_ readerInfo: ReaderInfo) {
        PDFKitReader.info = readerInfo
        pdfDocument = readerInfo.pdfDocument
        thumbnailStore = ThumbnailStore(pdfDocument: pdfDocument)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc fileprivate func handleSingleTap(_ sender: UITapGestureRecognizer) {
        self.statusBarHidden = !self.statusBarHidden
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PDFKitReader.info.isPad = traitCollection.userInterfaceIdiom == .pad
        
        setup()
    }
    
    private func setup() {
        self.navigationItem.title = PDFKitReader.info.title

        self.view.addSubview(pdfView)
        pdfView.document = PDFKitReader.info.pdfDocument
        pdfView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        pdfView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        pdfView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        pdfView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        if let pdfPage = pdfDocument.page(at: PDFKitReader.info.lastPageIndex) {
            pdfView.go(to: pdfPage)
        }
        
        // create a tap gesture recognizer
        let tapRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(handleSingleTap(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapRecognizer)
        
        var rightBarButtonItems: [UIBarButtonItem] = []
        // add thumbnail button
//        if let button = PDFKitReader.info.thumbnailOpenButton {
//            button.target = self
//            button.action = #selector(thumbnailButtonTapped)
//            rightBarButtonItems.append(button)
//        }
        
        if rightBarButtonItems.count > 0 {
            self.navigationItem.setRightBarButtonItems(rightBarButtonItems, animated: false)
        }
        
        // Place the slider on the toolbar.
        let slb = UIBarButtonItem(customView: slider)
        let sp1 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let sp2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        self.setToolbarItems([sp1, slb, sp2], animated: false)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        statusBarHidden = true
        splitViewController?.presentsWithGesture = false
    }
    
    /// Move directly to the specified page.
    ///
    /// - parameter pageIndex: Destination page index.
    ///
    func jumpTo(pageIndex: Int) {
        if let pdfPage = pdfDocument.page(at: pageIndex) {
            pdfView.go(to: pdfPage)
        }
        slider.value = Float(pageIndex)
    }
    
    /// Called when thumbnail display button tapped.
    ///
    @objc func thumbnailButtonTapped() {
        let vc = ThumbnailViewController(
            thumbnailStore: thumbnailStore,
            pageIndex: currentIndex) { [weak self] pageIndex  in
                guard let _ = self else { return }
                self!.jumpTo(pageIndex: pageIndex)
        }
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        
        // Necessary to turn off the status bar.
        vc.modalPresentationCapturesStatusBarAppearance = true
        
        statusBarHidden = true
        present(vc, animated: true, completion: nil)
    }
}

// MARK: - SliderDelegate

extension PDFKitReader: SliderDelegate {
    
    func onTouchDown(_ sender: Slider) {
        let originX = self.view.center.x - sender.thumbnailView.bounds.width / 2
        let originY = self.view.bounds.height - sender.thumbnailView.bounds.height - 44
        sender.thumbnailView.frame.origin = CGPoint(x: originX, y: originY)
        sender.value = Float(currentIndex)
        self.view.addSubview(sender.thumbnailView)
        onValueChanged(sender)
    }
    
    func onValueChanged(_ sender: Slider) {
        let pageIndex = sender.intValue
        let image = thumbnailStore[pageIndex]
        let text = "\(pageIndex + 1) of \(pdfDocument.pageCount)"
        sender.thumbnailImageView?.image = image
        sender.thumbnailLabel?.text = text
    }
    
    func onTouchCancel(_ sender: Slider) {
        sender.thumbnailView.removeFromSuperview()
        statusBarHidden = true
        let pageIndex = sender.intValue
        if pageIndex != currentIndex {
            jumpTo(pageIndex: pageIndex)
        }
    }
}
