# SwiftyMarkdown 1.0

SwiftyMarkdown converts Markdown files and strings into `NSAttributedString`s using sensible defaults and a Swift-style syntax. It uses dynamic type to set the font size correctly with whatever font you'd like to use.

## Fully Rebuilt For 2020!

SwiftyMarkdown now features a more robust and reliable rules-based line processing and tokenisation engine. It has added support for images stored in the bundle (`![Image](<Name In bundle>)`), codeblocks, blockquotes, and unordered lists!

Line-level attributes can now have a paragraph alignment applied to them (e.g. `h2.aligment = .center`), and links can be underlined by setting underlineLinks to `true`. 

It also uses the system color `.label` as the default font color on iOS 13 and above for Dark Mode support out of the box. 

## Installation

### CocoaPods:

`pod 'SwiftyMarkdown'`

### SPM: 

In Xcode, `File -> Swift Packages -> Add Package Dependency` and add the GitHub URL. 
