//
//  PKSimplePdfReader.swift
//  PKSimplePdfReader
//
//  Created by K.Nakano on 2018/08/13.
//  Copyright © 2018 K.Nakano. All rights reserved.
//

import PDFKit

public struct ReaderInfo {

    struct UserDefaultsKey {
        var crop: String?
        var page: String?
        init?(_ pdfDocument: PDFDocument) {
            guard let url = pdfDocument.documentURL else { return }
            let hash = url.dataRepresentation.md5.rawValue
            self.crop = hash + "_crop"
            self.page = hash + "_page"
        }
    }
    
    var userDefaultsKey: UserDefaultsKey?

    /// Get the page index you last read.
    ///
    lazy var lastPageIndex: Int = {
        if saveLastPageIndex, let key = userDefaultsKey?.page {
            return UserDefaults.standard.integer(forKey: key)
        }
        return 0
    }()

    /// Get the crop setting.
    ///
    lazy var unitCroppedRect: CGRect = {
        if let key = userDefaultsKey?.crop, let value = UserDefaults.standard.string(forKey: key) {
            return CGRectFromString(value)
        }
        return CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
    }()
    
    var navigationOrientation = UIPageViewControllerNavigationOrientation.horizontal
    
    var isPad = true
    
    var pdfDocument: PDFDocument

    // Other transition styles are not supported (for now).
    public var transitionStyle: UIPageViewControllerTransitionStyle = UIPageViewControllerTransitionStyle.pageCurl
    
    public var title: String = ""

    public var backgroundColor: UIColor? = UIColor.lightGray
    
    /// Determine whether to save the page index you last read or not.
    ///
    public var saveLastPageIndex = false

    public var thumbnailOpenButton: UIBarButtonItem? = {
        let btn = UIBarButtonItem(title: "thumbnail", style: .plain, target: nil, action: nil)
        return btn
    }()
    
    public var thumbnailCloseButton: UIBarButtonItem = {
        let btn = UIBarButtonItem(barButtonSystemItem: .stop, target: nil, action: nil)
        btn.tintColor = UIColor.white
        return btn
    }()
    
    public var cropMarginButton: UIBarButtonItem? = {
        let btn = UIBarButtonItem(title: "crop", style: .plain, target: nil, action: nil)
        return btn
    }()
    
    public var statusBarHiddenOriginal = false
    
    public init(of pdfDocument: PDFDocument) {
        self.pdfDocument = pdfDocument
        self.userDefaultsKey = UserDefaultsKey(pdfDocument)
    }
    
    /// Save page index.
    ///
    func savePageIndex(_ index: Int) {
        if let key = userDefaultsKey?.page {
            if index == 0 || !saveLastPageIndex  {
                UserDefaults.standard.removeObject(forKey: key)
            } else {
                UserDefaults.standard.set(index, forKey: key)
            }
        }
    }
    /// Save unit cropped rect.
    ///
    mutating func saveUnitCroppedRect() {
        if let key = userDefaultsKey?.crop {
            if unitCroppedRect.origin == CGPoint.zero && unitCroppedRect.size == CGSize(width: 1.0, height: 1.0) {
                UserDefaults.standard.removeObject(forKey: key)
            } else {
                UserDefaults.standard.set(NSStringFromCGRect(unitCroppedRect), forKey: key)
            }
        }
    }
}

public class PKSimplePdfReader {
    public class func create(_ readerInfo: ReaderInfo) -> UIViewController? {
        if readerInfo.transitionStyle == .pageCurl {
            return PKCurlReader(readerInfo)
        } else {
            return PDFKitReader(readerInfo)
        }
    }
}
