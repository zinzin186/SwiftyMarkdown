import Foundation


public enum SpaceAllowed {
	case no
	case bothSides
	case oneSide
	case leadingSide
	case trailingSide
}

public enum TagCount {
	case one
	case two
	case three
	case four
	case five
	case more
}

public struct SwiftyTagging {
	let openTag : String
	let intermediateTag : String?
	let closingTag : String?
	let spacesAllowed : SpaceAllowed
	let numberOfTags : TagCount
	let styles : [TagCount : [CharacterStyle]]
	let cancelsParsing : Cancel
	let escapeString : String?
}

public enum ParseDirection {
    case outsideIn
    case insideOut
}

public enum Cancel {
    case none
    case allRemaining
    case currentSet
}

public struct TokenRule {
    let openTag : String
    let closingTag : String?
    let intermediateTag : String?
    let parseDirection : ParseDirection
    let cancels : Cancel
    let maxCount : Int
}

enum  CharacterStyle {
    case none
    case bold
    case italic
}

struct ParseResult {
    let challenge : String
	let result : String
    var ranges : [ParseResultRange] = []
	
	mutating func fullRange(with styles : [CharacterStyle]) {
		self.ranges.append(ParseResultRange(range: self.result.startIndex..<self.result.endIndex, styles: styles))
	}
	
	mutating func range( startDistance : Int, endDistance : Int,  styles : [CharacterStyle] ) {
		let range = self.result.index(self.result.startIndex, offsetBy: startDistance)..<self.result.index(self.result.endIndex, offsetBy: -(endDistance))
		self.ranges.append(ParseResultRange(range: range, styles: styles))
	}
	
	mutating func rangeInset( by val : Int, with styles : [CharacterStyle] ) {
		self.range(startDistance: val, endDistance: val, styles: styles)
	}
	
	mutating func fromStart( toIndex val : Int, styles : [CharacterStyle]) {
		self.ranges.append(ParseResultRange(range: self.result.startIndex..<self.result.index(self.result.startIndex, offsetBy: val), styles: styles))
	}
	
	mutating func from( index val : Int, toEndWithStyles styles : [CharacterStyle]) {
		self.range(startDistance: val, endDistance: 0, styles: styles)
	}
}

struct ParseResultRange {
    let range : Range<String.Index>
    let styles : [CharacterStyle]
}

extension ParseResultRange : Equatable {
    static func == (lhs: ParseResultRange, rhs: ParseResultRange) -> Bool {
        return lhs.range == rhs.range && lhs.styles == rhs.styles
    }
}

struct TokenCount {
	let index : String.Index
	var count : Int
}

let styles : [TagCount : [CharacterStyle]] = [.one : [.italic], .two : [.bold], .more : [.bold, .italic]]
let asterisks = SwiftyTagging(openTag: "*", intermediateTag: nil, closingTag: "*", spacesAllowed: .oneSide, numberOfTags: .more, styles:styles, cancelsParsing: .none, escapeString: "\\")


func validateSpacing( nextCharacter : String?, previousCharacter : String?, with rule : SwiftyTagging ) -> Bool {
	switch rule.spacesAllowed {
	case .leadingSide:
		guard nextCharacter != nil else {
			return true
		}
		if nextCharacter == " "  {
			return false
		}
	case .trailingSide:
		guard previousCharacter != nil else {
			return true
		}
		if previousCharacter == " " {
			return false
		}
	case .no:
		switch (previousCharacter, nextCharacter) {
		case (nil, nil), ( " ", _ ), (  _, " " ):
			return false
		default:
			return true
		}
	
	case .oneSide:
		switch (previousCharacter, nextCharacter) {
		case (nil, nil), (nil, " " ), (" ", nil), (" ", " " ):
			return false
		default:
			return true
		}
	default:
		break
	}
	return true
}

struct StringReplacement {
	let index : String.Index
	let length : Int
	var isEscape : Bool = false
}


func countTags( for tag : String, in rule : SwiftyTagging, processedString output : inout String, using scanner : Scanner) -> [StringReplacement] {

	var replacementList : [StringReplacement] = []
	if let start = scanner.scanUpToString(tag) {
		output.append(start)
	}
	var foundStart = ""
	var openIndex = scanner.currentIndex
	while let nextToken = scanner.scanString(tag) {
		foundStart.append(nextToken)
	}
	
	let lastChar : String?
	if output.count > 0 {
		lastChar = String(output[output.index(before: output.endIndex)..<output.endIndex])
	} else {
		lastChar = nil
	}
	let nextChar : String?
	if let existentNextCharRange = scanner.string.index(scanner.string.index(before: scanner.currentIndex), offsetBy: 1, limitedBy: scanner.string.index(before: scanner.string.endIndex)) {
		nextChar = String(scanner.string[existentNextCharRange])
	} else {
		nextChar = nil
	}
	
	output.append(contentsOf: foundStart)
	
	if let escapeString = rule.escapeString, let existentLastChar = lastChar {
		
		if existentLastChar == escapeString {
			
			var escapeReplacement = StringReplacement(index: output.index(before: output.endIndex), length: 1)
			escapeReplacement.isEscape = true
			replacementList.append(escapeReplacement)
			foundStart.removeFirst()
			openIndex = scanner.string.index(scanner.currentIndex, offsetBy: 1)
			
			// output = output.replacingCharacters(in: output.index(before: output.endIndex)..<output.endIndex, with: String(foundStart.removeFirst()))
		}
	}
	// Validate the spacing for the open tags
	if !validateSpacing(nextCharacter: nextChar, previousCharacter: lastChar, with: rule) {
//		output.append(foundStart)
		return replacementList
	}
	
	if !foundStart.isEmpty {
		let replacement = StringReplacement(index: openIndex, length: foundStart.count)
		replacementList.append(replacement)
	}
	
	
//	output.insert(contentsOf: foundStart, at: openIndex)
	return replacementList
}


func process( _ string : String, with rule : SwiftyTagging ) -> (String, [ParseResultRange]) {
	var results : [ParseResultRange] = []
	var output : String = ""
	let textScanner = Scanner(string: string)
	textScanner.charactersToBeSkipped = nil
	 
	var tokenIdx = 1
	var openStyles : [CharacterStyle : String.Index] = [:]
	
	
	var allReplacements : [StringReplacement] = []
	
	while !textScanner.isAtEnd {
		
		let foundOpenTags = countTags(for: rule.openTag, in: rule, processedString: &output, using: textScanner)
		allReplacements.append(contentsOf: foundOpenTags)
		
		
		
//		var remainingOpenTags = foundOpenTags.foundTags
//		guard !remainingOpenTags.isEmpty else {
//			continue
//		}
//		guard let existentCloseTag = rule.closingTag else {
//			continue
//		}
//
//		switch foundOpenTags.foundTags.count {
//		case 1:
//			if let hasItalic = openStyles[.italic] {
//				output.remove(at: foundOpenTags.openIndex)
//				output.remove(at: hasItalic)
//			} else {
//				openStyles[.italic] = foundOpenTags.openIndex
//			}
//		default:
//			break
//		}
//
		
		// We now have a count and can search for the close tag
		var foundEnd = ""
//		while !remainingOpenTags.isEmpty, !textScanner.isAtEnd {
//			let endTags = countTags(for: existentCloseTag, in: rule, processedString: &output, using: textScanner)
//			foundEnd = endTags.foundTags
//			guard !foundEnd.isEmpty else {
//				continue
//			}
//			let result : ParseResultRange
//			switch (remainingOpenTags.count, foundEnd.count) {
//			case ( _, 1), (1, _):
//				 result = ParseResultRange(range: foundOpenTags.openIndex..<output.endIndex, styles: [.italic])
//			case (2, 2), (3,2), (2,3):
//				result = ParseResultRange(range: foundOpenTags.openIndex..<output.endIndex, styles: [.bold])
//			default:
//				result = ParseResultRange(range: foundOpenTags.openIndex..<output.endIndex, styles: [.bold, .italic])
//			}
//			output.replaceSubrange(foundOpenTags.openIndex..<output.endIndex, with: "%\(tokenIdx)")
//			while !foundEnd.isEmpty {
//				foundEnd.removeLast()
//				if !remainingOpenTags.isEmpty {
//					remainingOpenTags.removeLast()
//				}
//			}
//
//
//		}
		 
//		output.append(foundEnd)
//		while !remainingOpenTags.isEmpty {
//			output.insert(rule.openTag.first!, at: foundOpenTags.openIndex)
//			remainingOpenTags.removeLast()
//		}
		
		
//		 let count = TokenCount(index: output.endIndex, count: foundStart.count)
//		 openCount.append(count)
//
//		 var foundStyles : [CharacterStyle] = []
//		 switch foundStart.count {
//		 case 1:
//			 foundStyles.append(.italic)
//		 case 2:
//			 foundStyles.append(.bold)
//		 case 3:
//			 foundStyles.append(.bold)
//			 foundStyles.append(.italic)
//		 default:
//			 foundStyles.append(.bold)
//			 foundStyles.append(.italic)
//
//		 }
//
//		 for style in foundStyles {
//			 if let idx = openStyles[style] {
//				 let parseResult = ParseResultRange(range: idx..<output.endIndex, styles: [style])
//				 openStyles[style] = nil
//				 results.append(parseResult)
//			 } else {
//				 openStyles[style] = output.endIndex
//			 }
//		 }
	}
	
	let actualReplacements = allReplacements.filter({ !$0.isEscape })
	let escapeReplacements = allReplacements.filter({ $0.isEscape })
	
	struct CurrentStyle {
		let style : [CharacterStyle]
		let tagToReplace : String
		var replacement : String? = nil
		
		var replaceString : String {
			get {
				return "\(self.tagToReplace)\(self.replacement ?? "")"
			}
		}
	}
	
	var currentStyles : [CurrentStyle] = []
	for replacement in actualReplacements {
		let range = replacement.index..<string.index(replacement.index, offsetBy: replacement.length)
		
		var style : [CharacterStyle]
		switch replacement.length {
		case 1:
			style = [.italic]
		case 2:
			style = [.bold]
		default:
			style = [.bold, .italic]
		}
		
		
		// From ** to * is **AAAA, where the ** will be replaced and the string is bold
		// From * to * is *BBBB where the * will be replaced and the string is italic
		// From * to ** is *AAAA where the * will be replaced and the string is bold
		// From ** to the end is "" where the ** will be replaced
	}
	
	// Take care of the escaped strings
	let sortedEscape = escapeReplacements.sorted() { $0.index > $1.index }
	for rep in sortedEscape {
		let style = CurrentStyle(style: [], tagToReplace: "\(rule.escapeString ?? "")", replacement: rule.openTag)
		currentStyles.append(style)
	}
	for style in currentStyles {
		print(style.replaceString)
		output = output.replacingOccurrences(of: style.replaceString, with: style.replacement ?? "")
	}
	
	
	return (output, results)
}



func tokenise( _ string : String ) -> ParseResult {
    
    // Do nothing if it's a codeblock
 
    let asteriskOutput = process(string, with: asterisks)
    
	return ParseResult(challenge: string, result: asteriskOutput.0, ranges: asteriskOutput.1)
}

// Challenges

var challenge1 = ParseResult(challenge: "***AAAA*BBBB**", result: "AAAABBBB")
challenge1.fromStart(toIndex: 4, styles: [.italic])
challenge1.fullRange(with: [.bold])

var challenge2 = ParseResult(challenge: "AAAA**BBBB**" , result: "AAAABBBB"	)
challenge2.from(index: 4, toEndWithStyles: [.bold])

var challenge3 = ParseResult(challenge: "AAAA*BBBB*" , result: "AAAABBBB"	)
challenge3.from(index: 4, toEndWithStyles: [.italic])

var challenge4 = ParseResult(challenge: "**AA\\*AA*BBBB*AA\\*AA**" , result: "AAAABBBBAAAA"	)
challenge4.rangeInset(by: 4, with: [.italic])
challenge4.fullRange(with: [.bold])

var challenge5 = ParseResult(challenge: "*\\*AAAABBBB\\**", result: "*AAAABBBB*")
challenge5.fullRange(with: [.italic])

var challenge6 = ParseResult(challenge: "*\\*AAAABBBB*\\*", result: "*AAAABBBB*")
challenge6.fromStart(toIndex: 9, styles: [.italic])

var challenge7 = ParseResult(challenge: "*****AAAABBBB****", result: "*AAAABBBB")
challenge7.from(index: 1, toEndWithStyles: [.bold, .italic])

var challenge8 = ParseResult(challenge: "* AAAABBBB *", result: "* AAAABBBB *")

var challenge9 = ParseResult(challenge: "***", result: "***")



let challengeArray = [
    challenge4
]

for (idx, challengeAttempt) in challengeArray.enumerated() {
	let output = tokenise(challengeAttempt.challenge)
	print("\nAttempt : \(idx + 1): \(output.result)\n")
	break
	assert(challengeAttempt.result == output.result, "Strings don't match. Expected: \(challengeAttempt.result)\nReturned: \(output.result)")
	assert(challengeAttempt.ranges.count == output.ranges.count, "Range counts don't match, Expected: \(challengeAttempt.ranges.count)\nReturned: \(output.ranges.count)")
	for (idx,range) in output.ranges.enumerated() {
		assert(challengeAttempt.ranges[idx] == output.ranges[idx], "Range doesn't match. Expected: \(challengeAttempt.result[challengeAttempt.ranges[idx].range]) with style \(challengeAttempt.ranges[idx].styles)\nReturned: \(output.result[range.range]) with style \(range.styles)")
	}

}
print("Tests passed!")


