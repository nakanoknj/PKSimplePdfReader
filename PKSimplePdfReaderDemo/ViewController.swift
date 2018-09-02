//
//  ViewController.swift
//  PKPdfCurlReader
//
//  Created by K.Nakano on 2018/08/13.
//  Copyright © 2018 K.Nakano. All rights reserved.
//

import UIKit
import PKSimplePdfReader
import PDFKit

class ViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Demo"        
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
            // basic usage
            guard let path = Bundle.main.path(forResource: "input_pdf", ofType: "pdf"),
                let pdfDocument = PDFDocument(url: URL(fileURLWithPath: path)) else {
                    return
            }
            let info = ReaderInfo(of: pdfDocument)
            guard let vc = PKSimplePdfReader.create(info) else { return }
            navigationController?.pushViewController(vc, animated: true)
            
        case 1:
            // cuttomize
            guard let path = Bundle.main.path(forResource: "input_pdf", ofType: "pdf"),
                let pdfDocument = PDFDocument(url: URL(fileURLWithPath: path)) else {
                    return
            }
            var info = ReaderInfo(of: pdfDocument)
            info.title = "Title Of Document"
            info.backgroundColor = UIColor.orange
            info.saveLastPageIndex = true
            guard let vc = PKSimplePdfReader.create(info) else { return }
            navigationController?.pushViewController(vc, animated: true)
            
        default:
            break
        }
    }

}
