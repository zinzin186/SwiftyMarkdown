//
//  SwiftyMarkdown.swift
//  SwiftyMarkdown
//
//  Created by Simon Fairbairn on 05/03/2016.
//  Copyright © 2016 Voyage Travel Apps. All rights reserved.
//

import UIKit


protocol FontProperties {
	var fontName : String { get set }
	var color : UIColor { get set }
}


struct BasicStyles : FontProperties {
	var fontName = "AvenirNextCondensed-Medium"
	var color = UIColor.blackColor()
}

enum LineType : Int {
	case H1, H2, H3, H4, H5, H6, Body, Italic, Bold
}


class SwiftyMarkdown {
	
	var h1 = BasicStyles()
	var h2 = BasicStyles()
	var h3 = BasicStyles()
	var h4 = BasicStyles()
	var h5 = BasicStyles()
	var h6 = BasicStyles()
	
	var body = BasicStyles()
	var link = BasicStyles()
	var italic = BasicStyles(fontName: "AvenirNextCondensed-MediumItalic", color: UIColor.blackColor())
	var bold = BasicStyles(fontName: "AvenirNextCondensed-Bold", color: UIColor.blackColor())
	
	let string : String
	
	init(string : String ) {
		self.string = string
	}
	
	init?(url : NSURL ) {
		
		do {
			self.string = try NSString(contentsOfURL: url, encoding: NSUTF8StringEncoding) as String
			
		} catch {
			self.string = ""
			return nil
		}
	}
	
	func attributedString() -> NSAttributedString {
		let attributedString = NSMutableAttributedString(string: "")
		
		
		let lines = self.string.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
		
		var lineCount = 0
		
		let headings = ["# ", "## ", "### ", "#### ", "##### ", "###### "]
		
		
		var skipLine = false
		for line in lines {
			lineCount++
			if skipLine {
				skipLine = false
				continue
			}
			var headingFound = false
			for heading in headings {
				
				if let range =  line.rangeOfString(heading) where range.startIndex == line.startIndex {
					
					let startHeadingString = line.stringByReplacingCharactersInRange(range, withString: "")
					let endHeadingHash = " " + heading.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
					
					let finalHeadingString = startHeadingString.stringByReplacingOccurrencesOfString(endHeadingHash, withString: "")
					
					// Make Hx where x == current index
					let string = attributedStringFromString(finalHeadingString, withType: LineType(rawValue: headings.indexOf(heading)!)!)
					attributedString.appendAttributedString(string)
					headingFound = true
				}
			}
			if headingFound {
				continue
			}
			
			
			if lineCount  < lines.count {
				let nextLine = lines[lineCount]
				
				if let range = nextLine.rangeOfString("=") where range.startIndex == nextLine.startIndex {
					// Make H1
					let string = attributedStringFromString(line, withType: .H1)
					attributedString.appendAttributedString(string)
					skipLine = true
					continue
				}
				
				if let range = nextLine.rangeOfString("-") where range.startIndex == nextLine.startIndex {
					
					
					// Make H1
					let string = attributedStringFromString(line, withType: .H2)
					attributedString.appendAttributedString(string)
					skipLine = true
					continue
				}
			}
			
			if line.characters.count > 0 {
				
				let scanner = NSScanner(string: line)
				let instructionSet = NSCharacterSet(charactersInString: "\\*_")
				
				scanner.charactersToBeSkipped = nil
				
				var finalString : String = ""
				
				while !scanner.atEnd {
					
					var followingString : NSString?
					var string : NSString?
					// Get all the characters up to the ones we are interested in
					scanner.scanUpToCharactersFromSet(instructionSet, intoString: &string)
					
					if let hasString = string as? String {
						let bodyString = attributedStringFromString(hasString, withType: .Body)
						attributedString.appendAttributedString(bodyString)
						
						finalString = finalString + hasString
						
						var matchedCharacters : String = ""
						var tempCharacters : NSString?
						
						// Scan the ones we are interested in
						while scanner.scanCharactersFromSet(instructionSet, intoString: &tempCharacters) {
							if let chars = tempCharacters as? String {
								matchedCharacters = matchedCharacters + chars
							}
						}
						print("Matched Characters: \(matchedCharacters)")
						
						let location = scanner.scanLocation
						// If the next string after the characters is a space, then add it to the final string and continue
						if !scanner.scanUpToString(" ", intoString: nil) {
							
							let charAtts = attributedStringFromString(matchedCharacters, withType: .Body)
							
							attributedString.appendAttributedString(charAtts)
						} else {
							scanner.scanLocation = location
							scanner.scanUpToCharactersFromSet(instructionSet, intoString: &followingString)
							if let hasString = followingString as? String {
								let attString : NSAttributedString
								
								if matchedCharacters.containsString("\\") {
									attString = attributedStringFromString(matchedCharacters + hasString, withType: .Body)
								} else if matchedCharacters == "**" || matchedCharacters == "__" {
									attString = attributedStringFromString(hasString, withType: .Bold)
								} else {
									attString = attributedStringFromString(hasString, withType: .Italic)
								}
								
								
								
								attributedString.appendAttributedString(attString)
							}
							matchedCharacters = ""
							while scanner.scanCharactersFromSet(instructionSet, intoString: &tempCharacters) {
								if let chars = tempCharacters as? String {
									matchedCharacters = matchedCharacters + chars
								}
							}
							if matchedCharacters.containsString("\\") {
								let attString = attributedStringFromString(matchedCharacters, withType: .Body)
								
								attributedString.appendAttributedString(attString)
							}
							
						}
						
					}
					
					
				}
			}
			
			attributedString.appendAttributedString(NSAttributedString(string: "\n"))
			
		}
		
		return attributedString
	}
	
	// Make H1
	
	func attributedStringFromString(string : String, withType type : LineType ) -> NSAttributedString {
		var attributes : [String : AnyObject]
		let textStyle : String
		let fontName : String
		
		var appendNewLine = true
		
		switch type {
		case .H1:
			fontName = h1.fontName
			textStyle = UIFontTextStyleTitle1
			attributes = [NSForegroundColorAttributeName : h1.color]
		case .H2:
			fontName = h2.fontName
			textStyle = UIFontTextStyleTitle2
			attributes = [NSForegroundColorAttributeName : h2.color]
		case .H3:
			fontName = h3.fontName
			textStyle = UIFontTextStyleTitle3
			attributes = [NSForegroundColorAttributeName : h3.color]
		case .H4:
			fontName = h4.fontName
			textStyle = UIFontTextStyleHeadline
			attributes = [NSForegroundColorAttributeName : h4.color]
		case .H5:
			fontName = h5.fontName
			textStyle = UIFontTextStyleSubheadline
			attributes = [NSForegroundColorAttributeName : h5.color]
		case .H6:
			fontName = h6.fontName
			textStyle = UIFontTextStyleFootnote
			attributes = [NSForegroundColorAttributeName : h6.color]
		case .Italic:
			fontName = italic.fontName
			attributes = [NSForegroundColorAttributeName : italic.color]
			textStyle = UIFontTextStyleBody
			appendNewLine = false
		case .Bold:
			fontName = bold.fontName
			attributes = [NSForegroundColorAttributeName : bold.color]
			appendNewLine = false
			textStyle = UIFontTextStyleBody
		default:
			appendNewLine = false
			fontName = body.fontName
			textStyle = UIFontTextStyleBody
			attributes = [NSForegroundColorAttributeName:body.color]
			break
		}
		
		let font = UIFont.preferredFontForTextStyle(textStyle)
		let styleDescriptor = font.fontDescriptor()
		let styleSize = styleDescriptor.fontAttributes()[UIFontDescriptorSizeAttribute] as? CGFloat ?? CGFloat(14)
		
		let finalFont : UIFont
		if let font = UIFont(name: fontName, size: styleSize) {
			finalFont = font
		} else {
			finalFont = UIFont.preferredFontForTextStyle(textStyle)
		}
		
		attributes[NSFontAttributeName] = finalFont
		
		if appendNewLine {
			return NSAttributedString(string: string + "\n", attributes: attributes)
		} else {
			return NSAttributedString(string: string, attributes: attributes)
		}
	}
}
