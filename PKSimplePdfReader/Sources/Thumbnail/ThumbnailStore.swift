//
//  ThumbnailStore.swift
//  PKSimplePdfReader
//
//  Created by K.Nakano on 2018/09/02.
//  Copyright © 2018 K.Nakano. All rights reserved.
//

import PDFKit

class ThumbnailStore {
    
    private let pdfDocument: PDFDocument
    
    private var images: [UIImage?] = []
    
    var itemCount: Int {
        return self.pdfDocument.pageCount
    }
    
    init(pdfDocument: PDFDocument) {
        self.pdfDocument = pdfDocument
        // Create thumbnail images asynchronously.
        images = [UIImage?](repeating: nil, count: pdfDocument.pageCount)
        DispatchQueue.global(qos: .utility).async {
            for i in 0..<pdfDocument.pageCount {
                self.images[i] = self.getThumbnailImage(at: i)
            }
        }
    }
    
    subscript(index: Int) -> UIImage? {
        if itemCount == 0 { return nil }
        let safeIndex = max(0, min(index, itemCount - 1))
        return images[safeIndex]
    }
    
    /// Get thumbnail image at specific index.
    ///
    /// - parameter pageIndex: Index of page(zero origin).
    ///
    /// - returns: Thumbnail image.
    ///
    func getThumbnailImage(at pageIndex: Int) -> UIImage {
        let page = pdfDocument.safePage(at: pageIndex)
        return page.thumbnail(of: CGSize(width: 360, height: 480), for: .cropBox)
    }
    
}
