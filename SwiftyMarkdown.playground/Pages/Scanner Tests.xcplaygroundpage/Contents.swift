//: [Previous](@previous)

import Foundation

/// https://stackoverflow.com/questions/32305891/index-of-a-substring-in-a-string-with-swift/32306142#32306142
extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        var indices: [Index] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                indices.append(range.lowerBound)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return indices
    }
	func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<String.Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                result.append(range)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}

//let string = """
//# Heading 1
//## Heading 2
//### #Heading #3
//  #### #Heading 4 ####
// ##### Heading 5 ####
// ##### Heading 5 #### More
//# Hea
// Heading 1
//  =======
//    # Heading 1
//
//Here we go with some *italic*, **bold**, _italic_, __bold__, and a [link](https://www.neverendingvoyage.com/) to start with.
//
//"""

var challenges = """
*[**link**](   https://www.neverendingvoyage.com/   )* <- Should be a bold, italic link
[link](   https://www.neverendingvoyage.com/   ) <- Should be a link
[link](](   https://www.neverendingvoyage.com/   ))) <- Should be "link]())"
Here we go with some *italic*, **bold**, _italic_, __bold__, and a [link](https://www.neverendingvoyage.com/) to start with.
*[**link**](   https://www.neverendingvoyage.com/   )* <- Should be a bold, italic link
[link](](   https://www.neverendingvoyage.com/   ))) <- Should be "link]())"
\\[link\\]\\(https://www.neverendingvoyage.com/\\)
`code`, `**code**` ```code```
"""

let string = """
*_*`**code**`*_*
"""

enum LineStyle : Int {
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
//	case orderedList]
	
	func lineStyleForPrevious( ) -> LineStyle {
		switch self {
		case .previousH1:
			return .h1
		case .previousH2:
			return .h2
		default:
			return self
		}
	}
}

enum CharacterStyle : Int {
	case none
	case italic
	case underscoreItalic
	case bold
	case underscoreBold
	case code
	case link
	case image
}

struct LineAttribute  {
	let attributes : [CharacterStyle]
	let token : String
	let original : String
	let replacement : String
	var distance : String.IndexDistance {
		return replacement.distance(from: replacement.startIndex, to: replacement.endIndex)
	}
}

let tagList = "!\\_*`[]()"
let validMarkdownTags = CharacterSet(charactersIn: "!\\_*`[]()")


extension LineAttribute : Equatable {
	static func == ( _ lhs : LineAttribute, _ rhs : LineAttribute ) -> Bool {
		return lhs.attributes == rhs.attributes && lhs.token == rhs.token && lhs.original == rhs.original
	}
}

struct Line : CustomStringConvertible {
	let line : String
	let lineStyle : LineStyle
	var tokens : [Token] = []
	var description: String {
		return self.line
	}
}

extension Line : Equatable {
	static func == ( _ lhs : Line, _ rhs : Line ) -> Bool {
		return lhs.line == rhs.line && lhs.lineStyle == rhs.lineStyle && lhs.tokens == rhs.tokens
	}
}

struct MarkdownTag {
	var openTag : String
	var closingTag : String = ""
	var enclosedText : String = ""
	var url : String? = nil
	var closeURL : String? = nil
	var original : String {
		return "\(openTag)\(enclosedText)\(closingTag)\(url ?? "")\(closeURL ?? "")"
	}
}

struct Token {
	let token : String
	var markdownTag : MarkdownTag
	var replacementPrefix : String = ""
	var replacement : String
	var replacementSuffix : String = ""
	var foundAttributes : [CharacterStyle]
	var url : URL?
	var imageIdentifier : String?
	var replacementRange : Range<String.Index>? = nil
	var distance : String.IndexDistance {
		return replacement.distance(from: replacement.startIndex, to: replacement.endIndex)
	}
	
	mutating func replaceToken( in string : String ) -> String {
		var replacementString = string
		if let first = string.range(of: self.token)?.lowerBound {
			replacementString = string.replacingOccurrences(of: self.token, with: "\(self.replacementPrefix)\(self.replacement)\(self.replacementSuffix)")
			let range = first..<replacementString.index(first, offsetBy: self.distance)
			self.replacementRange = range
		}
		return replacementString
	}
}

extension Token : Equatable {
	static func == ( _ lhs : Token, _ rhs : Token ) -> Bool {
		return lhs.token == rhs.token && lhs.markdownTag.original == rhs.markdownTag.original
	}
}




func processLineLevelAttributes( _ text : String ) -> Line {
	var output : String = ""
	let textScanner = Scanner(string: text)
	textScanner.charactersToBeSkipped = nil
	
	var initialSpaceCount = 0
	while textScanner.scanString(" ") != nil {
		initialSpaceCount += 1
	}
	
	output = text.trimmingCharacters(in: .whitespaces)
	// This should be a code block and not processed as Markdown
	if initialSpaceCount >= 4 {
		return Line(line: output, lineStyle: .codeblock)
	}
	
	let heading1Characters = CharacterSet(charactersIn: "=")
	let heading2Characters = CharacterSet(charactersIn: "-")
	if output.unicodeScalars.allSatisfy({ heading1Characters.contains($0) }) {
		return Line(line: "", lineStyle: .previousH1)
	}
	
	if output.unicodeScalars.allSatisfy({ heading2Characters.contains($0) }) {
		return Line(line: "", lineStyle: .previousH2)
	}
	
	
	var foundType : LineStyle = .body
	while !textScanner.isAtEnd {
		if let firstGroup = textScanner.scanUpToString(" ") {
			_ = textScanner.scanString(" ")
			switch firstGroup {
			case "#":
				foundType = .h1
			case "##":
				foundType = .h2
			case "###":
				foundType = .h3
			case "####":
				foundType = .h4
			case "#####":
				foundType = .h5
			case "######":
				foundType = .h6
			case "-":
				foundType = .unorderedList
			case ">":
				foundType = .blockquote
			default:
				break
			}
			if foundType != .body {
				output = String(text[textScanner.currentIndex..<text.endIndex])
			}
			
			break
		} else {
			break
		}
	}
	output = output.trimmingCharacters(in: .whitespaces)
	
	let endScanner = Scanner(string: output)
	let offsetCount = (output.count >= 6) ? 6 : output.count - 1
	
	endScanner.currentIndex = text.index(output.endIndex, offsetBy: -offsetCount)
	
	while !endScanner.isAtEnd {
		if endScanner.scanUpToString("#") != nil {
			var indexToRemove = 0
			if endScanner.scanString("######") != nil {
				indexToRemove = 6
			} else if endScanner.scanString("#####") != nil {
				indexToRemove = 5
			} else if endScanner.scanString("####") != nil {
				indexToRemove = 4
			} else if endScanner.scanString("###") != nil {
				indexToRemove = 3
			} else if endScanner.scanString("##") != nil {
				indexToRemove = 2
			} else if endScanner.scanString("#") != nil {
				indexToRemove = 1
			}
			// If there is more text after this, then these are not end heading hashes
			if !endScanner.isAtEnd {
				break
			}
			output = String(output[output.startIndex..<output.index(output.endIndex, offsetBy: -indexToRemove)])
			break
		} else {
			break
		}
	}
	
	return Line(line: output.trimmingCharacters(in: .whitespaces), lineStyle: foundType)
}

func replaceTokens( in line : Line ) -> Line {
	var replacementString : String = line.line

	var newTokens : [Token] = []
	for var token in line.tokens {
		replacementString = token.replaceToken(in: replacementString)
		newTokens.append(token)
	}
	return Line(line: replacementString, lineStyle: line.lineStyle, tokens: newTokens)
}

func tokenise( _ line : Line ) -> Line {
	
	// Do nothing if it's a codeblock
	if line.lineStyle == .codeblock {
		return line
	}
	var output : String = ""
	let textScanner = Scanner(string: line.line)
	textScanner.charactersToBeSkipped = nil

	var tokenIdx = 1
	var tokens : [Token] = []
	while !textScanner.isAtEnd {
		
		if let start = textScanner.scanUpToCharacters(from: validMarkdownTags) {
			output.append(start)
		}
		if var startAttribute = textScanner.scanCharacters(from: validMarkdownTags) {
			var markdownTag = MarkdownTag(openTag: startAttribute)
			if var enclosedText = textScanner.scanUpToCharacters(from: validMarkdownTags) {
				markdownTag.enclosedText = enclosedText
				if let endAttribute = textScanner.scanCharacters(from:  validMarkdownTags ) {
					// If we reach here, there's a valid markdown tag and we can tokenise the string
					markdownTag.closingTag = endAttribute
					if endAttribute.contains( "](" ) || endAttribute.contains( "][" ) {
						if let enclosedURL = textScanner.scanUpToString(")") {
							markdownTag.url = enclosedURL
						}
						if let end = textScanner.scanCharacters(from: validMarkdownTags) {
							markdownTag.closeURL = end
						}
					}
					
					let token = Token(token: "%\(tokenIdx)", markdownTag: markdownTag, replacement: "", foundAttributes: [])
					tokens.append(token)
					output.append(token.token)
					tokenIdx += 1
				} else {
					
					for char in tagList {
						if char == "\\" {
							continue
						}
						startAttribute = startAttribute.replacingOccurrences(of: "\\\(char)", with: "\(char)")
						enclosedText = startAttribute.replacingOccurrences(of: "\\\(char)", with: "\(char)")
					}
					output.append ( startAttribute )
					output.append( enclosedText )
				}
			} else {
			
				for char in tagList {
					if char == "\\" {
						continue
					}
					startAttribute = startAttribute.replacingOccurrences(of: "\\\(char)", with: "\(char)")
				}
				
				output.append ( startAttribute )
			}
		} else {
			output.append( String(line.line[textScanner.currentIndex..<line.line.endIndex]) )
			break
		}
	}
	return Line(line: output, lineStyle: line.lineStyle, tokens: tokens)
}

func handleLinks( in token : Token ) -> Token {
	var newToken = token
	var newTag = token.markdownTag
	print( newTag.openTag )
	print( newTag.closingTag )
	print( newTag.closeURL ?? "" )
	if ( newTag.openTag.contains("[") || newTag.openTag.contains("![") ) && newTag.closingTag.contains("](") && (newTag.closeURL?.contains(")") ?? false) {
		if let range =  newTag.closingTag.ranges(of: "![").first {
			newTag.closingTag.removeSubrange(range)
		} else if let bracketIdx = newTag.openTag.firstIndex(of:"[") {
			newTag.openTag.remove(at: bracketIdx)
		}
		if let range =  newTag.closingTag.ranges(of: "](").first {
			newTag.closingTag.removeSubrange(range)
		}
		if let bracketIdx = newTag.closeURL?.firstIndex(of:")") {
			newTag.closeURL?.remove(at: bracketIdx)
		}
		if let existentURL = newTag.url?.trimmingCharacters(in: .whitespaces) {
			newTag.url = nil
			let url = URL(string: existentURL)
			if url?.scheme == nil {
				newToken.imageIdentifier = existentURL
			} else {
				newToken.url = url
			}
		}
		newToken.markdownTag = newTag
		newToken.foundAttributes.append(.link)
		newToken.replacement = newToken.markdownTag.enclosedText
	}

	return newToken
}

func handleFormatting( in token : Token ) -> Token {
	var newToken = token
	var attributes : Set<CharacterStyle> = []
	newToken.markdownTag.openTag = String(token.markdownTag.openTag.reversed())
	if newToken.markdownTag.openTag == token.markdownTag.closingTag {
		// Easy territory!
		if let idx = newToken.markdownTag.openTag.firstIndex(of: "`") {
			attributes.insert(.code)
			newToken.markdownTag.openTag.remove(at: idx)
			newToken.markdownTag.closingTag.remove(at: idx)

			let range = newToken.markdownTag.openTag.startIndex..<idx
			
			newToken.markdownTag.enclosedText = String(newToken.markdownTag.openTag[range]) + newToken.markdownTag.enclosedText
			newToken.markdownTag.openTag.removeSubrange(range)
			newToken.markdownTag.enclosedText = newToken.markdownTag.enclosedText + String(newToken.markdownTag.closingTag[range])
			newToken.markdownTag.closingTag.removeSubrange(range)
		}
		
		var openTag = newToken.markdownTag.openTag
		var count = 0
		var foundBold : Int? = nil
		var foundItalic : Int? = nil
		var skipNext = false
		
		for (idx,char) in newToken.markdownTag.openTag.enumerated() {
			if skipNext {
				skipNext = false
				continue
			}
			if char == "*" || char == "_" {
				if foundBold == nil {
					if idx < (newToken.markdownTag.openTag.count - 1) {
						let start = newToken.markdownTag.openTag.index(newToken.markdownTag.openTag.startIndex, offsetBy: idx)
						let end = newToken.markdownTag.openTag.index(newToken.markdownTag.openTag.startIndex, offsetBy: idx + 1)
						if newToken.markdownTag.openTag[end] == char {
							foundBold = idx
							skipNext = true
							attributes.insert(.bold)
							continue
						}
					}
				}
				if foundItalic == nil {
					foundItalic = idx
					attributes.insert(.italic)
				}
			}
			if foundBold != nil && foundItalic != nil {
				break
			}
		}
		if let italicIdx = foundItalic {
			print(italicIdx)
			let start = newToken.markdownTag.openTag.index(newToken.markdownTag.openTag.startIndex, offsetBy: italicIdx)
			newToken.markdownTag.openTag.remove(at: start)
			newToken.markdownTag.closingTag.remove(at: start)
			if let boldIdx = foundBold, boldIdx >= italicIdx {
				foundBold = boldIdx - 1
			}
		}
		if let boldIdx = foundBold {
			print(boldIdx)
			let start = newToken.markdownTag.openTag.index(newToken.markdownTag.openTag.startIndex, offsetBy: boldIdx)
			let end = newToken.markdownTag.openTag.index(newToken.markdownTag.openTag.startIndex, offsetBy: boldIdx + 1)
			newToken.markdownTag.openTag.removeSubrange(start...end)
			newToken.markdownTag.closingTag.removeSubrange(start...end)
		}
		
		
	} else {
		
	}
	newToken.markdownTag.openTag = String(newToken.markdownTag.openTag.reversed())
	print(newToken.replacementPrefix)
	
	return newToken
}

func attributes( from token : Token ) -> Token {
	var newToken = token
	for (idx, char) in tagList.enumerated() {
		if char == "\\" {
			continue
		}
		newToken.markdownTag.openTag = newToken.markdownTag.openTag.replacingOccurrences(of: "\\\(char)", with: "\(idx)")
		newToken.markdownTag.closingTag = newToken.markdownTag.closingTag.replacingOccurrences(of: "\\\(char)", with: "\(idx)")
		newToken.markdownTag.closeURL = newToken.markdownTag.closeURL?.replacingOccurrences(of: "\\\(char)", with: "\(idx)")
	}
	newToken = handleLinks(in: newToken)
	newToken = handleFormatting(in: newToken)
	
	for (idx, char) in tagList.enumerated() {
		if char == "\\" {
			continue
		}
		newToken.markdownTag.openTag = newToken.markdownTag.openTag.replacingOccurrences(of: "\(idx)", with: "\(char)")
		newToken.markdownTag.closingTag = newToken.markdownTag.closingTag.replacingOccurrences(of: "\(idx)", with: "\(char)")
		newToken.markdownTag.closeURL = newToken.markdownTag.closeURL?.replacingOccurrences(of: "\(idx)", with: "\(char)")
	}
	
	newToken.replacementPrefix = newToken.markdownTag.openTag
	newToken.replacement = newToken.markdownTag.enclosedText
	newToken.replacementSuffix = "\(newToken.markdownTag.closingTag)\(newToken.markdownTag.url ?? "")\(newToken.markdownTag.closeURL ?? "")"
	return newToken
}

func process( _ tokens : [Token] ) -> [Token] {
	
	var doneTokens : [Token] = []
	for token in tokens {
		doneTokens.append(attributes(from: token))
	}
	
	return doneTokens
}

func attributedString( for line : Line ) -> NSAttributedString {
	return NSAttributedString(string: line.line)
}

var foundAttributes : [Line] = []
for  heading in string.split(separator: "\n") {
	
	if heading.isEmpty {
		continue
	}
	
	let input = processLineLevelAttributes(String(heading))
	if (input.lineStyle == .previousH1 || input.lineStyle == .previousH2 ) && foundAttributes.count > 0 {
		if let idx = foundAttributes.firstIndex(of: foundAttributes.last!) {
			let updatedPrevious = foundAttributes.last!
			foundAttributes[idx] = Line(line: updatedPrevious.line, lineStyle: input.lineStyle.lineStyleForPrevious(), tokens: updatedPrevious.tokens)
		}
		continue
	}
	foundAttributes.append(input)
}

for output in foundAttributes {
	var processed = tokenise(output)
	processed.tokens = process(processed.tokens)
	processed = replaceTokens(in: processed)
	print(processed.line)
}





//: [Next](@next)
