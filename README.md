# PKSimplePdfReader
A Simple PDF Document Reader for iPhone/iPad.

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)


## Screenshots
#### Curl Transition
<img src="https://github.com/nakanoknj/PKSimplePdfReader/blob/images/curl.gif">

#### Page Jump #1
<img src="https://github.com/nakanoknj/PKSimplePdfReader/blob/images/jump1.gif">

#### Page Jump #2
<img src="https://github.com/nakanoknj/PKSimplePdfReader/blob/images/jump2.gif">

#### Crop Margins
<img src="https://github.com/nakanoknj/PKSimplePdfReader/blob/images/crop.gif">

## Requirements
- Swift 4+
- iOS 11+

## Installation
### Carthage
```
github "nakanoknj/PKSimplePdfReader"
```

## Usage
```
import PDFKit
import PKSimplePdfReader


# In you view controller
guard
    let path = Bundle.main.path(forResource: "input_pdf", ofType: "pdf"),
    let pdfDocument = PDFDocument(url: URL(fileURLWithPath: path)) else
{
    return
}
var info = ReaderInfo(of: pdfDocument)
info.title = "The Title"
guard let vc = PKSimplePdfReader.create(info) else { return }
navigationController?.pushViewController(vc, animated: true)
```
