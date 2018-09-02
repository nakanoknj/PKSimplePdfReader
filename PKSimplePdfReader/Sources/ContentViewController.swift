//
//  ContentViewController.swift
//  PKSimplePdfReader
//
//  Created by K.Nakano on 2018/08/13.
//  Copyright © 2018 K.Nakano. All rights reserved.
//

import PDFKit

class ContentViewController: UIViewController {
    
    var pageIndex: Int {
        guard let pageRef = self.pdfPage.pageRef else {
            return 0
        }
        return pageRef.pageNumber - 1
    }
    
    private var pdfPage: PDFPage
    
    private var contentSize: CGSize

    deinit {
        #if DEBUG
        print(#file, #function, #line)
        #endif
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(pdfPage: PDFPage, contentSize: CGSize) {
        self.pdfPage = pdfPage
        self.contentSize = contentSize
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.bounds.size = contentSize
        if let sv = ScrollView(frame: self.view.bounds, pdfPage: pdfPage) {
            self.view.addSubview(sv)
        }
    }
}
