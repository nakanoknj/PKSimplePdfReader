//
//  Extensions.swift
//  PKSimplePdfReader
//
//  Created by K.Nakano on 2018/08/29.
//  Copyright © 2018 K.Nakano. All rights reserved.
//

import Foundation
import PDFKit

// MARK: - PDFDocument

extension PDFDocument {
    
    var lastPageIndex: Int {
        return pageCount - 1
    }
    
    func safePage(at index: Int) -> PDFPage {
        let safeIndex = max(0, min(index, lastPageIndex))
        return page(at: safeIndex)!
    }
}
