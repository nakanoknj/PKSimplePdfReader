//
//  PDFKitReader.swift
//  PKSimplePdfReader
//
//  Created by K.Nakano on 2018/09/10.
//  Copyright © 2018 K.Nakano. All rights reserved.
//

import PDFKit

class PDFKitReader: UIViewController {

    static var info: ReaderInfo!

    /// Thumbnail image management class
    ///
    private var thumbnailStore: ThumbnailStore
    
    /// PDF Document
    ///
    private var pdfDocument: PDFDocument
    
    private var statusBarHidden = false {
        didSet {
            self.navigationController?.setNavigationBarHidden(statusBarHidden, animated: false)
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

        self.navigationItem.title = PDFKitReader.info.title
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapRecognizer)
        
        let pdfView = PDFView(frame: self.view.bounds)
        pdfView.autoScales = true
        pdfView.usePageViewController(true, withViewOptions: nil)
        pdfView.displayDirection = .horizontal
        pdfView.document = PDFKitReader.info.pdfDocument
        self.view.addSubview(pdfView)
        
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        pdfView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        pdfView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        pdfView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
    }
    
}
