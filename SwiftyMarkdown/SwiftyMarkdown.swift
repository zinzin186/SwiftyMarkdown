//
//  SwiftyMarkdown.swift
//  SwiftyMarkdown
//
//  Created by Simon Fairbairn on 05/03/2016.
//  Copyright © 2016 Voyage Travel Apps. All rights reserved.
//

import UIKit

enum CharacterStyle : CharacterStyling {
	case none
	case bold
	case italic
	case code
}

enum MarkdownLineStyle : LineStyling {
    var shouldTokeniseLine: Bool {
        switch self {
        case .codeblock:
            return false
        default:
            return true
        }
        
    }
    
    case h1
    case h2
    case h3
    case h4
    case h5
    case h6
    case previousH1
    case previousH2
    case body
    case blockquote
    case codeblock
    case unorderedList
    func styleIfFoundStyleAffectsPreviousLine() -> LineStyling? {
        switch self {
        case .previousH1:
            return MarkdownLineStyle.h1
        case .previousH2:
            return MarkdownLineStyle.h2
        default :
            return nil
        }
    }
}


@objc public protocol FontProperties {
	var fontName : String? { get set }
	var color : UIColor { get set }
	var fontSize : CGFloat { get set }
}


/**
A struct defining the styles that can be applied to the parsed Markdown. The `fontName` property is optional, and if it's not set then the `fontName` property of the Body style will be applied.

If that is not set, then the system default will be used.
*/
@objc open class BasicStyles : NSObject, FontProperties {
	public var fontName : String? 
	public var color = UIColor.black
	public var fontSize : CGFloat = 0.0
}

/// A class that takes a [Markdown](https://daringfireball.net/projects/markdown/) string or file and returns an NSAttributedString with the applied styles. Supports Dynamic Type.
@objc open class SwiftyMarkdown: NSObject {
	static let lineRules = [
		LineRule(token: "=", type: MarkdownLineStyle.previousH1, removeFrom: .entireLine, changeAppliesTo: .previous),
		LineRule(token: "-", type: MarkdownLineStyle.previousH2, removeFrom: .entireLine, changeAppliesTo: .previous),
		LineRule(token: "    ", type: MarkdownLineStyle.codeblock, removeFrom: .leading, shouldTrim: false),
		LineRule(token: "\t", type: MarkdownLineStyle.codeblock, removeFrom: .leading, shouldTrim: false),
		LineRule(token: ">",type : MarkdownLineStyle.blockquote, removeFrom: .leading),
		LineRule(token: "- ",type : MarkdownLineStyle.unorderedList, removeFrom: .leading),
		LineRule(token: "###### ",type : MarkdownLineStyle.h6, removeFrom: .both),
		LineRule(token: "##### ",type : MarkdownLineStyle.h5, removeFrom: .both),
		LineRule(token: "#### ",type : MarkdownLineStyle.h4, removeFrom: .both),
		LineRule(token: "### ",type : MarkdownLineStyle.h3, removeFrom: .both),
		LineRule(token: "## ",type : MarkdownLineStyle.h2, removeFrom: .both),
		LineRule(token: "# ",type : MarkdownLineStyle.h1, removeFrom: .both)
	]
	
	static let characterRules = [
		SwiftyTagging(openTag: "`", intermediateTag: nil, closingTag: nil, escapeString: "\\", styles: [1 : [CharacterStyle.code]], maxTags: 1),
		SwiftyTagging(openTag: "*", intermediateTag: nil, closingTag: "*", escapeString: "\\", styles: [1 : [.italic], 2 : [.bold], 3 : [CharacterStyle.bold, CharacterStyle.italic]], maxTags: 3),
		SwiftyTagging(openTag: "_", intermediateTag: nil, closingTag: nil, escapeString: "\\", styles: [1 : [.italic], 2 : [.bold], 3 : [CharacterStyle.bold, CharacterStyle.italic]], maxTags: 3)
	]
	
	let lineProcessor = SwiftyLineProcessor(rules: SwiftyMarkdown.lineRules, defaultRule: MarkdownLineStyle.body)
	let tokeniser = SwiftyTokeniser(with: SwiftyMarkdown.characterRules)
	
	/// The styles to apply to any H1 headers found in the Markdown
	open var h1 = BasicStyles()
	
	/// The styles to apply to any H2 headers found in the Markdown
	open var h2 = BasicStyles()
	
	/// The styles to apply to any H3 headers found in the Markdown
	open var h3 = BasicStyles()
	
	/// The styles to apply to any H4 headers found in the Markdown
	open var h4 = BasicStyles()
	
	/// The styles to apply to any H5 headers found in the Markdown
	open var h5 = BasicStyles()
	
	/// The styles to apply to any H6 headers found in the Markdown
	open var h6 = BasicStyles()
	
	/// The default body styles. These are the base styles and will be used for e.g. headers if no other styles override them.
	open var body = BasicStyles()
	
	/// The styles to apply to any links found in the Markdown
	open var link = BasicStyles()
	
	/// The styles to apply to any bold text found in the Markdown
	open var bold = BasicStyles()
	
	/// The styles to apply to any italic text found in the Markdown
	open var italic = BasicStyles()
	
	/// The styles to apply to any code blocks or inline code text found in the Markdown
	open var code = BasicStyles()
	
	
	var currentType : MarkdownLineStyle = .body
	
	
	let string : String
	
	let tagList = "!\\_*`[]()"
	let validMarkdownTags = CharacterSet(charactersIn: "!\\_*`[]()")

	
	/**
	
	- parameter string: A string containing [Markdown](https://daringfireball.net/projects/markdown/) syntax to be converted to an NSAttributedString
	
	- returns: An initialized SwiftyMarkdown object
	*/
	public init(string : String ) {
		self.string = string
	}
	
	/**
	A failable initializer that takes a URL and attempts to read it as a UTF-8 string
	
	- parameter url: The location of the file to read
	
	- returns: An initialized SwiftyMarkdown object, or nil if the string couldn't be read
	*/
	public init?(url : URL ) {
		
		do {
			self.string = try NSString(contentsOf: url, encoding: String.Encoding.utf8.rawValue) as String
			
		} catch {
			self.string = ""
			return nil
		}
	}
	
	/**
	Set font size for all styles
	
	- parameter size: size of font
	*/
	open func setFontSizeForAllStyles(with size: CGFloat) {
		h1.fontSize = size
		h2.fontSize = size
		h3.fontSize = size
		h4.fontSize = size
		h5.fontSize = size
		h6.fontSize = size
		body.fontSize = size
		italic.fontSize = size
		code.fontSize = size
		link.fontSize = size
	}
	
	open func setFontColorForAllStyles(with color: UIColor) {
		h1.color = color
		h2.color = color
		h3.color = color
		h4.color = color
		h5.color = color
		h6.color = color
		body.color = color
		italic.color = color
		code.color = color
		link.color = color
	}
	
	open func setFontNameForAllStyles(with name: String) {
		h1.fontName = name
		h2.fontName = name
		h3.fontName = name
		h4.fontName = name
		h5.fontName = name
		h6.fontName = name
		body.fontName = name
		italic.fontName = name
		code.fontName = name
		link.fontName = name
	}
	
	
	
	/**
	Generates an NSAttributedString from the string or URL passed at initialisation. Custom fonts or styles are applied to the appropriate elements when this method is called.
	
	- returns: An NSAttributedString with the styles applied
	*/
	open func attributedString() -> NSAttributedString {
		let attributedString = NSMutableAttributedString(string: "")
		let foundAttributes : [SwiftyLine] = lineProcessor.process(self.string)
		
		var strings : [String] = []
		for line in foundAttributes {
			let finalTokens = self.tokeniser.process(line.line)
			
			let string = finalTokens.map({ $0.outputString }).joined()
			strings.append(string)
		}
		
		let finalString = strings.joined(separator: "\n")
		
		return NSAttributedString(string: finalString)
	}
	
	
}

extension SwiftyMarkdown {
	
	func attributedStringFromString(_ string : String, withStyle style : MarkdownLineStyle, attributes : [NSAttributedString.Key : AnyObject] = [:] ) -> NSAttributedString {
		let textStyle : UIFont.TextStyle
		var fontName : String?
		var attributes = attributes
		var fontSize : CGFloat?
		
		// What type are we and is there a font name set?
		
		
		switch currentType {
		case .h1:
			fontName = h1.fontName
			fontSize = h1.fontSize
			if #available(iOS 9, *) {
				textStyle = UIFont.TextStyle.title1
			} else {
				textStyle = UIFont.TextStyle.headline
			}
			attributes[NSAttributedString.Key.foregroundColor] = h1.color
		case .h2:
			fontName = h2.fontName
			fontSize = h2.fontSize
			if #available(iOS 9, *) {
				textStyle = UIFont.TextStyle.title2
			} else {
				textStyle = UIFont.TextStyle.headline
			}
			attributes[NSAttributedString.Key.foregroundColor] = h2.color
		case .h3:
			fontName = h3.fontName
			fontSize = h3.fontSize
			if #available(iOS 9, *) {
				textStyle = UIFont.TextStyle.title2
			} else {
				textStyle = UIFont.TextStyle.subheadline
			}
			attributes[NSAttributedString.Key.foregroundColor] = h3.color
		case .h4:
			fontName = h4.fontName
			fontSize = h4.fontSize
			textStyle = UIFont.TextStyle.headline
			attributes[NSAttributedString.Key.foregroundColor] = h4.color
		case .h5:
			fontName = h5.fontName
			fontSize = h5.fontSize
			textStyle = UIFont.TextStyle.subheadline
			attributes[NSAttributedString.Key.foregroundColor] = h5.color
		case .h6:
			fontName = h6.fontName
			fontSize = h6.fontSize
			textStyle = UIFont.TextStyle.footnote
			attributes[NSAttributedString.Key.foregroundColor] = h6.color
		default:
			fontName = body.fontName
			fontSize = body.fontSize
			textStyle = UIFont.TextStyle.body
			attributes[NSAttributedString.Key.foregroundColor] = body.color
			break
		}
		
		// Check for code
		
//		if style == .code {
//			fontName = code.fontName
//			fontSize = code.fontSize
//			attributes[NSAttributedString.Key.foregroundColor] = code.color
//		}
//
//		if style == .link {
//			fontName = link.fontName
//			fontSize = link.fontSize
//			attributes[NSAttributedString.Key.foregroundColor] = link.color
//		}
		
		// Fallback to body
		if let _ = fontName {
			
		} else {
			fontName = body.fontName
		}
		
		fontSize = fontSize == 0.0 ? nil : fontSize
		let font = UIFont.preferredFont(forTextStyle: textStyle)
		let styleDescriptor = font.fontDescriptor
		let styleSize = fontSize ?? styleDescriptor.fontAttributes[UIFontDescriptor.AttributeName.size] as? CGFloat ?? CGFloat(14)
		
		var finalFont : UIFont
		if let finalFontName = fontName, let font = UIFont(name: finalFontName, size: styleSize) {
			finalFont = font
		} else {
			finalFont = UIFont.preferredFont(forTextStyle:  textStyle)
		}
		
		let finalFontDescriptor = finalFont.fontDescriptor
//		if style == .italic {
//			if let italicDescriptor = finalFontDescriptor.withSymbolicTraits(.traitItalic) {
//				finalFont = UIFont(descriptor: italicDescriptor, size: styleSize)
//			}
//			
//		}
//		if style == .bold {
//			if let boldDescriptor = finalFontDescriptor.withSymbolicTraits(.traitBold) {
//				finalFont = UIFont(descriptor: boldDescriptor, size: styleSize)
//			}
//		}
		
		
		attributes[NSAttributedString.Key.font] = finalFont
		
		return NSAttributedString(string: string, attributes: attributes)
	}
}
